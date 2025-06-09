defmodule AthenaCapture.ConversationMonitor do
  @moduledoc """
  Monitors Claude conversation logs and emits events for athena-ingest processing.
  
  Watches ~/.claude/projects/ for new conversation sessions and processes them
  into structured events that feed into the athena knowledge graph pipeline.
  
  Claude Code Logs Location:
  - Main logs directory: ~/.claude/projects/
  - Conversation files: *.jsonl format
  - Project-specific directories like: ~/.claude/projects/-Users-j-Code-project-name/
  """
  
  use GenServer
  require Logger
  
  @claude_projects_dir Path.expand("~/.claude/projects")
  @check_interval 5_000  # Check every 5 seconds
  
  defstruct [
    :watcher_pid,
    :known_sessions,
    :last_check
  ]
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def get_active_sessions do
    GenServer.call(__MODULE__, :get_active_sessions)
  end
  
  # Server Callbacks
  
  def init(_opts) do
    Logger.info("Starting ConversationMonitor for #{@claude_projects_dir}")
    
    state = %__MODULE__{
      known_sessions: MapSet.new(),
      last_check: DateTime.utc_now()
    }
    
    # Start file system watcher
    {:ok, watcher_pid} = start_file_watcher()
    
    # Schedule periodic check for missed files
    schedule_check()
    
    {:ok, %{state | watcher_pid: watcher_pid}}
  end
  
  def handle_call(:get_active_sessions, _from, state) do
    sessions = scan_for_sessions()
    {:reply, sessions, state}
  end
  
  def handle_info({:file_event, _watcher_pid, {path, events}}, state) do
    if String.ends_with?(path, ".jsonl") and :modified in events do
      handle_conversation_file(path, state)
    else
      {:noreply, state}
    end
  end
  
  def handle_info(:periodic_check, state) do
    new_state = check_for_new_sessions(state)
    schedule_check()
    {:noreply, new_state}
  end
  
  def handle_info({:file_event, _watcher_pid, :stop}, state) do
    {:noreply, state}
  end
  
  # Private Functions
  
  defp start_file_watcher do
    FileSystem.start_link(dirs: [@claude_projects_dir], name: :claude_watcher)
  end
  
  defp schedule_check do
    Process.send_after(self(), :periodic_check, @check_interval)
  end
  
  defp check_for_new_sessions(state) do
    current_sessions = scan_for_sessions()
    new_sessions = MapSet.difference(current_sessions, state.known_sessions)
    
    # Process any new session files
    Enum.each(new_sessions, &process_session_file/1)
    
    %{state | 
      known_sessions: current_sessions,
      last_check: DateTime.utc_now()
    }
  end
  
  defp scan_for_sessions do
    @claude_projects_dir
    |> Path.join("**/*.jsonl")
    |> Path.wildcard()
    |> MapSet.new()
  end
  
  defp handle_conversation_file(path, state) do
    Logger.debug("Processing conversation file: #{path}")
    
    case extract_session_metadata(path) do
      {:ok, metadata} -> 
        emit_conversation_event("session_updated", metadata)
        {:noreply, state}
      {:error, reason} ->
        Logger.warning("Failed to process #{path}: #{reason}")
        {:noreply, state}
    end
  end
  
  defp process_session_file(path) do
    Logger.info("New conversation session detected: #{path}")
    
    case extract_session_metadata(path) do
      {:ok, metadata} -> 
        emit_conversation_event("session_created", metadata)
      {:error, reason} ->
        Logger.warning("Failed to process new session #{path}: #{reason}")
    end
  end
  
  defp extract_session_metadata(path) do
    with {:ok, stat} <- File.stat(path),
         {:ok, sample} <- read_session_sample(path),
         {:ok, metadata} <- parse_session_metadata(path, stat, sample) do
      {:ok, metadata}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp read_session_sample(path) do
    # Read first and last few lines to extract metadata without loading entire file
    with {:ok, content} <- File.read(path) do
      lines = String.split(content, "\n", trim: true)
      sample_lines = Enum.take(lines, 3) ++ Enum.take(lines, -2)
      {:ok, sample_lines}
    end
  end
  
  defp parse_session_metadata(path, stat, sample_lines) do
    try do
      # Parse first line to get session info
      first_line = List.first(sample_lines) || "{}"
      session_data = Jason.decode!(first_line)
      
      project_name = extract_project_name(path)
      session_id = session_data["sessionId"]
      
      metadata = %{
        session_id: session_id,
        project: project_name,
        file_path: path,
        size: stat.size,
        modified_at: stat.mtime,
        message_count: length(sample_lines),
        tools_used: extract_tools_from_sample(sample_lines),
        participants: ["human", extract_model_info(session_data)]
      }
      
      {:ok, metadata}
    rescue
      exception -> {:error, Exception.message(exception)}
    end
  end
  
  defp extract_project_name(path) do
    path
    |> Path.dirname()
    |> Path.basename()
    |> String.replace("-Users-j-Code-athena-", "")
    |> String.replace("-", "_")
  end
  
  defp extract_model_info(session_data) do
    get_in(session_data, ["message", "model"]) || "claude-unknown"
  end
  
  defp extract_tools_from_sample(sample_lines) do
    sample_lines
    |> Enum.map(&Jason.decode!/1)
    |> Enum.flat_map(fn line ->
      case get_in(line, ["message", "content"]) do
        content when is_list(content) ->
          Enum.filter_map(content, 
            &Map.has_key?(&1, "name"), 
            &Map.get(&1, "name"))
        _ -> []
      end
    end)
    |> Enum.uniq()
  end
  
  defp emit_conversation_event(action, metadata) do
    event = %{
      type: "conversation_event",
      action: action,
      timestamp: DateTime.utc_now(),
      metadata: metadata
    }
    
    Logger.info("Emitting conversation event: #{action} for session #{metadata.session_id}")
    
    # Ring the bell! 🔔
    AthenaCapture.EventDashboard.record_event("conversation_#{action}", metadata)
    
    # Store to durable SQLite storage 💾
    AthenaCapture.EventStore.store_event("conversation_#{action}", metadata, event.timestamp)
    
    # TODO: Integrate with actual event bus/pipeline to athena-ingest
    # For now, just log the structured event
    Logger.debug("Event: #{inspect(event, pretty: true)}")
  end
end