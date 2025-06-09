defmodule ClaudeCollector.ChatLogMonitor do
  use GenServer
  require Logger

  @claude_app_support_path "~/Library/Application Support/Claude"
  @poll_interval 5_000  # 5 seconds

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Expand the path and start monitoring
    expanded_path = Path.expand(@claude_app_support_path)
    
    if File.exists?(expanded_path) do
      Logger.info("Starting Claude chat log monitor for: #{expanded_path}")
      
      # Start file system watcher
      {:ok, watcher_pid} = FileSystem.start_link(dirs: [expanded_path])
      FileSystem.subscribe(watcher_pid)
      
      # Also poll for changes in case watcher misses events
      schedule_poll()
      
      {:ok, %{
        watcher_pid: watcher_pid,
        watched_path: expanded_path,
        last_scan: DateTime.utc_now(),
        processed_files: MapSet.new()
      }}
    else
      Logger.warn("Claude Application Support directory not found: #{expanded_path}")
      {:ok, %{watched_path: nil}}
    end
  end

  @impl true
  def handle_info({:file_event, watcher_pid, {path, events}}, state) do
    if state.watcher_pid == watcher_pid do
      Logger.debug("File event detected: #{path} - #{inspect(events)}")
      
      # Process if it's a chat-related file
      if is_chat_file?(path) and :modified in events do
        process_chat_file(path)
      end
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_info(:poll, state) do
    if state.watched_path do
      scan_for_new_files(state)
    end
    
    schedule_poll()
    {:noreply, state}
  end

  @impl true
  def handle_info({:file_event, watcher_pid, :stop}, state) do
    Logger.info("File system watcher stopped")
    {:noreply, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, @poll_interval)
  end

  defp scan_for_new_files(state) do
    if state.watched_path do
      try do
        # Look for chat files (conversations, logs, etc.)
        pattern = Path.join(state.watched_path, "**/*.{json,log,txt}")
        
        Enum.each(Path.wildcard(pattern), fn file_path ->
          if is_chat_file?(file_path) and not MapSet.member?(state.processed_files, file_path) do
            stat = File.stat!(file_path)
            
            # Only process files modified since last scan
            if DateTime.compare(stat.mtime, state.last_scan) == :gt do
              process_chat_file(file_path)
              MapSet.put(state.processed_files, file_path)
            end
          end
        end)
      rescue
        e ->
          Logger.error("Error scanning chat files: #{inspect(e)}")
      end
    end
  end

  defp is_chat_file?(path) do
    basename = Path.basename(path)
    
    # Look for patterns that indicate chat files
    String.contains?(basename, "conversation") or
    String.contains?(basename, "chat") or
    String.contains?(basename, "messages") or
    String.ends_with?(basename, ".json")
  end

  defp process_chat_file(file_path) do
    Logger.info("Processing chat file: #{file_path}")
    
    try do
      case File.read(file_path) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, data} ->
              # Create chat event
              event = %{
                id: UUID.uuid4(),
                type: "claude_chat",
                timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
                source: "claude_application",
                file_path: file_path,
                content: data,
                metadata: %{
                  file_size: byte_size(content),
                  last_modified: get_file_mtime(file_path)
                }
              }
              
              # Send to Broadway pipeline
              ClaudeCollector.EventPublisher.publish_event(event)
              
            {:error, _} ->
              # Try processing as plain text
              event = %{
                id: UUID.uuid4(),
                type: "claude_chat_text",
                timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
                source: "claude_application",
                file_path: file_path,
                content: %{raw_text: content},
                metadata: %{
                  file_size: byte_size(content),
                  last_modified: get_file_mtime(file_path)
                }
              }
              
              ClaudeCollector.EventPublisher.publish_event(event)
          end
          
        {:error, reason} ->
          Logger.error("Failed to read chat file #{file_path}: #{reason}")
      end
    rescue
      e ->
        Logger.error("Error processing chat file #{file_path}: #{inspect(e)}")
    end
  end

  defp get_file_mtime(file_path) do
    case File.stat(file_path) do
      {:ok, stat} -> DateTime.from_naive!(stat.mtime, "Etc/UTC") |> DateTime.to_iso8601()
      {:error, _} -> DateTime.utc_now() |> DateTime.to_iso8601()
    end
  end
end