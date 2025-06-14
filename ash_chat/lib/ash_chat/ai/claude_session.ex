defmodule AshChat.AI.ClaudeSession do
  @moduledoc """
  Persistent Claude session manager using tmux for long-lived interactions.
  
  Maintains a persistent Claude CLI session to eliminate cold start overhead
  and enable stateful multi-turn conversations.
  """
  
  use GenServer
  require Logger
  
  defstruct [
    :session_name,
    :tmux_session,
    :status,
    :current_task_id,
    :task_queue,
    :last_activity,
    :restart_count
  ]
  
  @type status :: :starting | :ready | :thinking | :responding | :error | :stopping
  
  @type state :: %__MODULE__{
    session_name: String.t(),
    tmux_session: String.t(),
    status: status(),
    current_task_id: String.t() | nil,
    task_queue: [{String.t(), String.t(), reference()}],  # {task_id, prompt, from}
    last_activity: DateTime.t(),
    restart_count: non_neg_integer()
  }
  
  # Public API
  
  @doc "Start a Claude session with the given name"
  def start_link(opts) do
    session_name = Keyword.fetch!(opts, :session_name)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(session_name))
  end
  
  @doc "Submit a prompt to the Claude session"
  def submit(session_name, prompt, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 30_000)
    GenServer.call(via_tuple(session_name), {:submit, prompt}, timeout)
  end
  
  @doc "Get current session status"
  def status(session_name) do
    GenServer.call(via_tuple(session_name), :status)
  end
  
  @doc "Get session info"
  def info(session_name) do
    GenServer.call(via_tuple(session_name), :info)
  end
  
  @doc "Stop the session"
  def stop(session_name) do
    GenServer.stop(via_tuple(session_name))
  end
  
  # GenServer callbacks
  
  @impl true
  def init(opts) do
    session_name = Keyword.fetch!(opts, :session_name)
    tmux_session = "claude_#{session_name}"
    
    state = %__MODULE__{
      session_name: session_name,
      tmux_session: tmux_session,
      status: :starting,
      current_task_id: nil,
      task_queue: [],
      last_activity: DateTime.utc_now(),
      restart_count: 0
    }
    
    # Start tmux session asynchronously
    send(self(), :start_tmux_session)
    
    Logger.info("Claude session #{session_name} initializing")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:submit, prompt}, from, %{status: :ready} = state) do
    task_id = generate_task_id()
    
    case send_prompt_to_tmux(state.tmux_session, prompt, task_id) do
      :ok ->
        new_state = %{state | 
          status: :thinking,
          current_task_id: task_id,
          last_activity: DateTime.utc_now()
        }
        
        # Start monitoring for completion
        send(self(), {:check_completion, task_id, from})
        
        {:noreply, new_state}
        
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call({:submit, _prompt}, _from, state) do
    {:reply, {:error, "Session not ready, status: #{state.status}"}, state}
  end
  
  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end
  
  def handle_call(:info, _from, state) do
    info = %{
      status: state.status,
      queue_length: length(state.task_queue),
      last_activity: state.last_activity,
      restart_count: state.restart_count
    }
    {:reply, info, state}
  end
  
  @impl true
  def handle_info(:start_tmux_session, state) do
    case create_tmux_session(state.tmux_session) do
      :ok ->
        Logger.info("Claude session #{state.session_name} ready")
        {:noreply, %{state | status: :ready}}
        
      {:error, reason} ->
        Logger.error("Failed to create tmux session: #{reason}")
        {:noreply, %{state | status: :error}}
    end
  end
  
  def handle_info({:check_completion, task_id, from}, state) do
    if state.current_task_id == task_id do
      case check_tmux_output(state.tmux_session, task_id) do
        {:complete, response} ->
          GenServer.reply(from, {:ok, response})
          {:noreply, %{state | status: :ready, current_task_id: nil}}
          
        :still_working ->
          # Check again in 500ms
          Process.send_after(self(), {:check_completion, task_id, from}, 500)
          {:noreply, state}
          
        {:error, reason} ->
          GenServer.reply(from, {:error, reason})
          {:noreply, %{state | status: :error, current_task_id: nil}}
      end
    else
      # Task was superseded, ignore
      {:noreply, state}
    end
  end
  
  @impl true
  def terminate(_reason, state) do
    cleanup_tmux_session(state.tmux_session)
    :ok
  end
  
  # Private functions
  
  defp via_tuple(session_name) do
    {:via, Registry, {AshChat.ClaudeSessionRegistry, session_name}}
  end
  
  defp generate_task_id do
    "task_#{System.unique_integer([:positive])}"
  end
  
  defp create_tmux_session(session_name) do
    # Check if tmux is available
    case System.cmd("which", ["tmux"], stderr_to_stdout: true) do
      {_, 0} ->
        # tmux is available, create session
        cmd = "tmux new-session -d -s #{session_name} -c /tmp 'claude --dangerously-skip-permissions --model sonnet'"
        case System.shell(cmd, stderr_to_stdout: true) do
          {_output, 0} ->
            # Give Claude a moment to start
            Process.sleep(1000)
            :ok
            
          {error, exit_code} ->
            {:error, "tmux session creation failed: #{error} (exit: #{exit_code})"}
        end
        
      {_, _} ->
        {:error, "tmux not found in PATH"}
    end
  end
  
  defp send_prompt_to_tmux(session_name, prompt, _task_id) do
    # Use System.cmd to avoid shell quoting issues
    case System.cmd("tmux", ["send-keys", "-t", session_name, prompt, "Enter"], stderr_to_stdout: true) do
      {_output, 0} -> :ok
      {error, _} -> {:error, "Failed to send prompt: #{error}"}
    end
  end
  
  defp check_tmux_output(session_name, _task_id) do
    case System.cmd("tmux", ["capture-pane", "-t", session_name, "-p"], stderr_to_stdout: true) do
      {output, 0} ->
        lines = String.split(output, "\n")
        
        cond do
          # Look for Claude ready for next prompt (clean prompt box with cursor)
          has_ready_prompt?(lines) ->
            response = extract_response_from_output(output)
            {:complete, response}
            
          # Look for working indicators  
          Enum.any?(lines, &working_indicator?/1) ->
            :still_working
            
          # If output is very short, probably still starting
          String.length(output) < 100 ->
            :still_working
            
          true ->
            # Wait a bit more by default
            :still_working
        end
        
      {error, _} ->
        {:error, "Failed to capture tmux output: #{error}"}
    end
  end
  
  defp has_ready_prompt?(lines) do
    # Look for the characteristic prompt box that appears when Claude is ready
    Enum.any?(lines, fn line ->
      # Look for the prompt box pattern: "│ > " 
      String.contains?(line, "│ > ") and 
      # Make sure it's not in a response area
      not String.contains?(line, "Bypassing Permissions") and
      # Should be relatively short (just the prompt, not a response)
      String.length(String.trim(line)) < 50
    end)
  end
  
  defp working_indicator?(line) do
    String.contains?(line, "Bypassing Permissions") or
    String.contains?(line, "Thinking...") or
    String.contains?(line, "Processing") or
    # Look for the progress/status area at bottom
    (String.contains?(line, "│") and String.length(String.trim(line)) < 20)
  end
  
  defp extract_response_from_output(output) do
    lines = String.split(output, "\n")
    
    # Find the response area between prompt boxes
    # Look for lines that contain Claude's actual response (not UI elements)
    response_lines = 
      lines
      |> Enum.reject(fn line ->
        # Skip UI chrome and empty lines
        String.trim(line) == "" or
        String.contains?(line, "╭") or
        String.contains?(line, "╰") or  
        String.contains?(line, "│ >") or
        String.contains?(line, "Bypassing Permissions") or
        String.contains?(line, "What's new:") or
        String.contains?(line, "Welcome to Claude") or
        String.starts_with?(String.trim(line), "•")
      end)
      |> Enum.take_while(fn line ->
        # Stop when we hit the next prompt area
        not String.contains?(line, "│ > ")
      end)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(fn line -> line == "" end)
    
    case response_lines do
      [] -> "No response captured"
      lines -> Enum.join(lines, "\n")
    end
  end
  
  defp cleanup_tmux_session(session_name) do
    case System.cmd("which", ["tmux"], stderr_to_stdout: true) do
      {_, 0} ->
        case System.cmd("tmux", ["kill-session", "-t", session_name], stderr_to_stdout: true) do
          {_, _} -> :ok  # Don't care about exit code - session might not exist
        end
      {_, _} ->
        :ok  # tmux not available, nothing to clean up
    end
  end
end