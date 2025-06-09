defmodule AthenaCapture.ScreenshotCapture do
  @moduledoc """
  Captures screenshots and emits events for athena-ingest processing.
  
  Provides functionality to capture full screen, active window, or specific windows
  and processes them into structured events that feed into the athena knowledge graph pipeline.
  
  Screenshot Storage:
  - Image files: Saved to disk at ~/.athena/screenshots/ (PNG format)
  - Metadata: Stored in SQLite via EventStore (window title, app name, file path, etc.)
  - Events: Tracked in EventDashboard for real-time monitoring
  """
  
  use GenServer
  require Logger
  
  @screenshots_dir Path.expand("~/.athena/screenshots")
  @default_format "png"
  
  defstruct [
    :screenshots_dir,
    :last_capture
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def capture_screen(opts \\ []) do
    GenServer.call(__MODULE__, {:capture_screen, opts})
  end
  
  def capture_window(window_id, opts \\ []) do
    GenServer.call(__MODULE__, {:capture_window, window_id, opts})
  end
  
  def capture_active_window(opts \\ []) do
    GenServer.call(__MODULE__, {:capture_active_window, opts})
  end
  
  def capture_interactive(opts \\ []) do
    GenServer.call(__MODULE__, {:capture_interactive, opts})
  end
  
  # Server Callbacks
  
  def init(_opts) do
    Logger.info("Starting ScreenshotCapture - saving screenshots to #{@screenshots_dir}")
    
    # Ensure screenshots directory exists
    File.mkdir_p!(@screenshots_dir)
    
    state = %__MODULE__{
      screenshots_dir: @screenshots_dir,
      last_capture: nil
    }
    
    {:ok, state}
  end
  
  def handle_call({:capture_screen, opts}, _from, state) do
    result = do_capture_screen(opts, state)
    {:reply, result, update_last_capture(state, result)}
  end
  
  def handle_call({:capture_window, window_id, opts}, _from, state) do
    result = do_capture_window(window_id, opts, state)
    {:reply, result, update_last_capture(state, result)}
  end
  
  def handle_call({:capture_active_window, opts}, _from, state) do
    result = do_capture_active_window(opts, state)
    {:reply, result, update_last_capture(state, result)}
  end
  
  def handle_call({:capture_interactive, opts}, _from, state) do
    result = do_capture_interactive(opts, state)
    {:reply, result, update_last_capture(state, result)}
  end
  
  # Private Functions
  
  defp do_capture_screen(opts, state) do
    filename = generate_filename("screen", opts)
    filepath = Path.join(state.screenshots_dir, filename)
    
    case run_screencapture(["-x", filepath]) do
      :ok ->
        metadata = build_metadata("screen", filepath, opts)
        emit_screenshot_event("screen_captured", metadata)
        {:ok, %{file: filepath, metadata: metadata}}
      {:error, reason} ->
        Logger.error("Failed to capture screen: #{reason}")
        {:error, reason}
    end
  end
  
  defp do_capture_window(window_id, opts, state) do
    filename = generate_filename("window_#{window_id}", opts)
    filepath = Path.join(state.screenshots_dir, filename)
    
    case run_screencapture(["-x", "-l", to_string(window_id), filepath]) do
      :ok ->
        metadata = build_metadata("window", filepath, Map.put(opts, :window_id, window_id))
        emit_screenshot_event("window_captured", metadata)
        {:ok, %{file: filepath, metadata: metadata}}
      {:error, reason} ->
        Logger.error("Failed to capture window #{window_id}: #{reason}")
        {:error, reason}
    end
  end
  
  defp do_capture_active_window(opts, state) do
    # First get active window metadata
    window_info = get_active_window_info()
    
    filename = generate_filename("active_window", opts)
    filepath = Path.join(state.screenshots_dir, filename)
    
    # WISDOM: Keep it simple! Full screen capture with window metadata works reliably
    # vs complex window ID detection that breaks across different apps and macOS versions.
    # The metadata tells us what window was active, which is often more valuable than
    # a perfect crop that might fail to capture.
    case run_screencapture(["-x", filepath]) do
      :ok ->
        metadata = build_metadata("active_window", filepath, Map.merge(opts, window_info))
        emit_screenshot_event("active_window_captured", metadata)
        {:ok, %{file: filepath, metadata: metadata}}
      {:error, reason} ->
        Logger.error("Failed to capture active window: #{reason}")
        {:error, reason}
    end
  end
  
  defp do_capture_interactive(opts, state) do
    filename = generate_filename("interactive", opts)
    filepath = Path.join(state.screenshots_dir, filename)
    
    case run_screencapture(["-x", "-s", filepath]) do
      :ok ->
        metadata = build_metadata("interactive", filepath, opts)
        emit_screenshot_event("interactive_captured", metadata)
        {:ok, %{file: filepath, metadata: metadata}}
      {:error, reason} ->
        Logger.error("Failed to capture interactive selection: #{reason}")
        {:error, reason}
    end
  end
  
  defp run_screencapture(args) do
    case System.cmd("screencapture", args, stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {error, _code} -> {:error, error}
    end
  end
  
  defp generate_filename(type, opts) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    format = Map.get(opts, :format, @default_format)
    tag = Map.get(opts, :tag, "")
    
    base_name = if tag != "", do: "#{type}_#{tag}_#{timestamp}", else: "#{type}_#{timestamp}"
    "#{base_name}.#{format}"
  end
  
  defp build_metadata(capture_type, filepath, opts) do
    {:ok, stat} = File.stat(filepath)
    
    %{
      capture_type: capture_type,
      file_path: filepath,
      file_name: Path.basename(filepath),
      size: stat.size,
      created_at: stat.ctime,
      format: Path.extname(filepath) |> String.trim_leading("."),
      options: opts,
      checksum: calculate_checksum(filepath)
    }
  end
  
  defp calculate_checksum(filepath) do
    filepath
    |> File.stream!([], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
  
  defp get_active_window_info do
    # Get active window metadata using AppleScript
    script = """
    tell application "System Events"
      set frontApp to first application process whose frontmost is true
      set appName to name of frontApp
      try
        set windowTitle to title of front window of frontApp
      on error
        set windowTitle to "No Title"
      end try
      return appName & "|" & windowTitle
    end tell
    """
    
    case System.cmd("osascript", ["-e", script], stderr_to_stdout: true) do
      {output, 0} ->
        [app_name, window_title] = String.trim(output) |> String.split("|", parts: 2)
        %{app_name: app_name, window_title: window_title}
      {_error, _code} ->
        %{app_name: "Unknown", window_title: "Unknown"}
    end
  end
  
  defp emit_screenshot_event(action, metadata) do
    event = %{
      type: "screenshot_event",
      action: action,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
    
    window_context = if metadata[:app_name], do: " (#{metadata.app_name})", else: ""
    Logger.info("Emitting screenshot event: #{action} for #{metadata.file_name}#{window_context}")
    
    # Ring the bell! 📸
    AthenaCapture.EventDashboard.record_event("screenshot_#{action}", metadata)
    
    # Store to durable SQLite storage 💾
    AthenaCapture.EventStore.store_event("screenshot_#{action}", metadata, event.timestamp)
    
    # TODO: Integrate with actual event bus/pipeline to athena-ingest
    # For now, just log the structured event
    Logger.debug("Event: #{inspect(event, pretty: true)}")
  end
  
  defp update_last_capture(state, result) do
    case result do
      {:ok, %{metadata: metadata}} ->
        %{state | last_capture: metadata}
      _ ->
        state
    end
  end
end