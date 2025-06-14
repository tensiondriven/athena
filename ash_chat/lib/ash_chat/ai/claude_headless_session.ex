defmodule AshChat.AI.ClaudeHeadlessSession do
  @moduledoc """
  Fast Claude session using headless mode with streaming JSON output.
  
  Much faster than interactive tmux approach - uses Claude's built-in
  --print --output-format stream-json for programmatic control.
  """
  
  use GenServer
  require Logger
  
  defstruct [
    :session_name,
    :session_id,
    :status,
    :current_task_id,
    :task_queue,
    :last_activity,
    :model,
    :cwd
  ]
  
  @type status :: :ready | :processing | :error
  
  @type state :: %__MODULE__{
    session_name: String.t(),
    session_id: String.t() | nil,
    status: status(),
    current_task_id: String.t() | nil,
    task_queue: [{String.t(), String.t(), reference()}],  # {task_id, prompt, from}
    last_activity: DateTime.t(),
    model: String.t(),
    cwd: String.t()
  }
  
  # Public API
  
  @doc "Start a Claude headless session"
  def start_link(opts) do
    session_name = Keyword.fetch!(opts, :session_name)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(session_name))
  end
  
  @doc "Submit a prompt to Claude"
  def submit(session_name, prompt, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 15_000)
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
    model = Keyword.get(opts, :model, "sonnet")
    cwd = Keyword.get(opts, :cwd, "/tmp")
    
    state = %__MODULE__{
      session_name: session_name,
      session_id: nil,
      status: :ready,
      current_task_id: nil,
      task_queue: [],
      last_activity: DateTime.utc_now(),
      model: model,
      cwd: cwd
    }
    
    Logger.info("Claude headless session #{session_name} ready")
    {:ok, state}
  end
  
  @impl true
  def handle_call({:submit, prompt}, _from, %{status: :ready} = state) do
    task_id = generate_task_id()
    
    new_state = %{state | 
      status: :processing,
      current_task_id: task_id,
      last_activity: DateTime.utc_now()
    }
    
    # Execute Claude synchronously for now to debug
    result = execute_claude_headless(prompt, state.model, state.cwd)
    
    final_state = %{new_state | status: :ready, current_task_id: nil}
    {:reply, result, final_state}
  end
  
  def handle_call({:submit, _prompt}, _from, state) do
    {:reply, {:error, "Session busy, status: #{state.status}"}, state}
  end
  
  def handle_call(:status, _from, state) do
    {:reply, state.status, state}
  end
  
  def handle_call(:info, _from, state) do
    info = %{
      status: state.status,
      session_id: state.session_id,
      queue_length: length(state.task_queue),
      last_activity: state.last_activity,
      model: state.model,
      cwd: state.cwd
    }
    {:reply, info, state}
  end
  
  @impl true
  def handle_cast({:task_complete, task_id, from, result}, state) do
    if state.current_task_id == task_id do
      GenServer.reply(from, result)
      {:noreply, %{state | status: :ready, current_task_id: nil}}
    else
      # Task was superseded, ignore
      {:noreply, state}
    end
  end
  
  # Private functions
  
  defp via_tuple(session_name) do
    {:via, Registry, {AshChat.ClaudeSessionRegistry, "headless_#{session_name}"}}
  end
  
  defp generate_task_id do
    "task_#{System.unique_integer([:positive])}"
  end
  
  defp execute_claude_headless(prompt, model, cwd) do
    # Use external script to avoid GenServer environment issues
    script_path = "/Users/j/Code/athena/claude_headless_runner.sh"
    
    Logger.info("Executing Claude via script: #{script_path}")
    Logger.info("Model: #{model}, Working directory: #{cwd}")
    
    try do
      case System.cmd(script_path, [model, prompt], 
        cd: cwd,
        stderr_to_stdout: true
      ) do
        {output, 0} ->
          Logger.info("Claude execution successful, parsing output...")
          parse_claude_stream_output(output)
          
        {error, exit_code} ->
          Logger.error("Claude script execution failed: #{error} (exit: #{exit_code})")
          {:error, "Claude script execution failed: #{error}"}
      end
    rescue
      e ->
        Logger.error("Claude script execution exception: #{inspect(e)}")
        {:error, "Claude script execution exception: #{inspect(e)}"}
    end
  end
  
  defp parse_claude_stream_output(output) do
    # Parse the streaming JSON output to extract the response
    lines = String.split(output, "\n")
    
    # Look for the assistant message with the actual response
    response = 
      lines
      |> Enum.map(&parse_json_line/1)
      |> Enum.filter(& &1)
      |> Enum.find_value(fn parsed ->
        case parsed do
          %{"type" => "assistant", "message" => %{"content" => content}} ->
            extract_text_content(content)
          _ ->
            nil
        end
      end)
    
    case response do
      nil -> {:error, "No response found in Claude output"}
      text -> {:ok, text}
    end
  end
  
  defp parse_json_line(line) do
    case Jason.decode(String.trim(line)) do
      {:ok, parsed} -> parsed
      {:error, _} -> nil
    end
  end
  
  defp extract_text_content(content) when is_list(content) do
    content
    |> Enum.find_value(fn
      %{"type" => "text", "text" => text} -> text
      _ -> nil
    end)
  end
  
  defp extract_text_content(_), do: nil
end