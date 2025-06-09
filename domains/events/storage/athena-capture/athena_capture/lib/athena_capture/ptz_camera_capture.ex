defmodule AthenaCapture.PTZCameraCapture do
  @moduledoc """
  Captures still images from PTZ cameras and emits events for athena-ingest processing.
  
  Provides functionality to position PTZ camera (pan, tilt, zoom) and capture high-quality
  still images, processing them into structured events that feed into the athena knowledge graph pipeline.
  
  PTZ Camera Workflow:
  1. Position camera (pan/tilt/zoom operations)
  2. Capture still image using imagesnap
  3. Store with metadata including position data
  
  Image Storage:
  - Image files: Saved to disk at ~/.athena/ptz_captures/ (JPEG format for efficiency)
  - Metadata: Stored in SQLite via EventStore (position, settings, file path, etc.)
  - Events: Tracked in EventDashboard for real-time monitoring
  """
  
  use GenServer
  require Logger
  
  @captures_dir Path.expand("~/.athena/ptz_captures")
  @default_format "jpg"
  @ptz_executable "/Users/j/Code/logi-ptz/webcam-ptz/webcam-ptz"
  
  defstruct [
    :captures_dir,
    :last_capture,
    :last_position,
    :ptz_executable
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def capture_with_position(position_opts, capture_opts \\ []) do
    GenServer.call(__MODULE__, {:capture_with_position, position_opts, capture_opts}, 30_000)
  end
  
  def capture_current_position(opts \\ []) do
    GenServer.call(__MODULE__, {:capture_current_position, opts})
  end
  
  def position_camera(position_opts) do
    GenServer.call(__MODULE__, {:position_camera, position_opts})
  end
  
  def get_last_position do
    GenServer.call(__MODULE__, :get_last_position)
  end
  
  # Server Callbacks
  
  def init(opts) do
    Logger.info("Starting PTZCameraCapture - saving captures to #{@captures_dir}")
    
    # Ensure captures directory exists
    File.mkdir_p!(@captures_dir)
    
    # Verify PTZ executable exists
    ptz_executable = Keyword.get(opts, :ptz_executable, @ptz_executable)
    case File.exists?(ptz_executable) do
      true ->
        Logger.info("PTZ executable found at #{ptz_executable}")
      false ->
        Logger.warning("PTZ executable not found at #{ptz_executable} - positioning will fail")
    end
    
    state = %__MODULE__{
      captures_dir: @captures_dir,
      last_capture: nil,
      last_position: %{},
      ptz_executable: ptz_executable
    }
    
    {:ok, state}
  end
  
  def handle_call({:capture_with_position, position_opts, capture_opts}, _from, state) do
    result = do_capture_with_position(position_opts, capture_opts, state)
    {:reply, result, update_last_capture_and_position(state, result, position_opts)}
  end
  
  def handle_call({:capture_current_position, opts}, _from, state) do
    result = do_capture_current_position(opts, state)
    {:reply, result, update_last_capture(state, result)}
  end
  
  def handle_call({:position_camera, position_opts}, _from, state) do
    result = do_position_camera(position_opts, state)
    new_state = case result do
      :ok -> %{state | last_position: position_opts}
      _ -> state
    end
    {:reply, result, new_state}
  end
  
  def handle_call(:get_last_position, _from, state) do
    {:reply, state.last_position, state}
  end
  
  # Private Functions
  
  defp do_capture_with_position(position_opts, capture_opts, state) do
    Logger.info("PTZ sequence: positioning then capturing")
    
    # Step 1: Position the camera
    case do_position_camera(position_opts, state) do
      :ok ->
        # Brief pause to allow camera to settle after movement
        Process.sleep(500)
        
        # Step 2: Capture the image
        do_capture_current_position(capture_opts, state)
        
      {:error, reason} ->
        Logger.error("Failed to position camera: #{reason}")
        {:error, "positioning_failed: #{reason}"}
    end
  end
  
  defp do_capture_current_position(opts, state) do
    filename = generate_filename("ptz_capture", opts)
    filepath = Path.join(state.captures_dir, filename)
    
    case run_imagesnap([filepath]) do
      :ok ->
        metadata = build_metadata("ptz_capture", filepath, opts, state.last_position)
        emit_ptz_event("ptz_image_captured", metadata)
        {:ok, %{file: filepath, metadata: metadata}}
      {:error, reason} ->
        Logger.error("Failed to capture PTZ image: #{reason}")
        {:error, reason}
    end
  end
  
  defp do_position_camera(position_opts, state) do
    # Build PTZ command arguments
    args = build_ptz_args(position_opts)
    
    case File.exists?(state.ptz_executable) do
      true ->
        Logger.info("Positioning PTZ camera: #{Enum.join(args, " ")}")
        case System.cmd(state.ptz_executable, args, stderr_to_stdout: true) do
          {_output, 0} -> 
            Logger.info("PTZ positioning successful")
            :ok
          {error, code} -> 
            Logger.error("PTZ positioning failed (exit code #{code}): #{error}")
            {:error, "ptz_command_failed: #{error}"}
        end
      false ->
        Logger.error("PTZ executable not found at #{state.ptz_executable}")
        {:error, "ptz_executable_missing"}
    end
  end
  
  defp build_ptz_args(position_opts) do
    # Convert position options to PTZ command arguments
    # Expected format: ./webcam-ptz pan <position> [tilt <position>] [zoom <level>]
    args = []
    
    # Pan operation (required for most positioning)
    args = case Map.get(position_opts, :pan) do
      nil -> args
      pan_pos -> args ++ ["pan", to_string(pan_pos)]
    end
    
    # Tilt operation (optional)
    args = case Map.get(position_opts, :tilt) do
      nil -> args
      tilt_pos -> args ++ ["tilt", to_string(tilt_pos)]
    end
    
    # Zoom operation (optional)
    args = case Map.get(position_opts, :zoom) do
      nil -> args
      zoom_level -> args ++ ["zoom", to_string(zoom_level)]
    end
    
    # If no operations specified, default to pan middle
    if Enum.empty?(args), do: ["pan", "middle"], else: args
  end
  
  defp run_imagesnap(args) do
    case System.cmd("imagesnap", args, stderr_to_stdout: true) do
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
  
  defp build_metadata(capture_type, filepath, opts, position) do
    {:ok, stat} = File.stat(filepath)
    
    %{
      capture_type: capture_type,
      file_path: filepath,
      file_name: Path.basename(filepath),
      size: stat.size,
      created_at: stat.ctime,
      format: Path.extname(filepath) |> String.trim_leading("."),
      options: opts,
      position: position,
      checksum: calculate_checksum(filepath),
      camera_type: "ptz",
      executable_path: @ptz_executable
    }
  end
  
  defp calculate_checksum(filepath) do
    filepath
    |> File.stream!([], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end
  
  defp emit_ptz_event(action, metadata) do
    event = %{
      type: "ptz_event",
      action: action,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
    
    position_info = case metadata[:position] do
      pos when map_size(pos) > 0 ->
        pos_str = pos |> Enum.map(fn {k, v} -> "#{k}:#{v}" end) |> Enum.join(" ")
        " at position [#{pos_str}]"
      _ -> ""
    end
    
    Logger.info("Emitting PTZ event: #{action} for #{metadata.file_name}#{position_info}")
    
    # Ring the bell! 📸
    AthenaCapture.EventDashboard.record_event("ptz_#{action}", metadata)
    
    # Store to durable SQLite storage 💾
    AthenaCapture.EventStore.store_event("ptz_#{action}", metadata, event.timestamp)
    
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
  
  defp update_last_capture_and_position(state, result, position_opts) do
    updated_state = update_last_capture(state, result)
    case result do
      {:ok, _} -> %{updated_state | last_position: position_opts}
      _ -> updated_state
    end
  end
end