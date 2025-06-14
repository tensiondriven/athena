defmodule AshChat.AI.ClaudeSessionSupervisor do
  @moduledoc """
  Supervisor for Claude session workers with Registry for name resolution.
  """
  
  use Supervisor
  require Logger
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    children = [
      # Registry for session name → pid mapping
      {Registry, keys: :unique, name: AshChat.ClaudeSessionRegistry},
      
      # Dynamic supervisor for session workers
      {DynamicSupervisor, name: AshChat.ClaudeSessionDynamicSupervisor, strategy: :one_for_one}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
  
  @doc "Start a new Claude session"
  def start_session(session_name, opts \\ []) do
    child_spec = {
      AshChat.AI.ClaudeSession,
      [session_name: session_name] ++ opts
    }
    
    case DynamicSupervisor.start_child(AshChat.ClaudeSessionDynamicSupervisor, child_spec) do
      {:ok, pid} ->
        Logger.info("Started Claude session: #{session_name}")
        {:ok, pid}
        
      {:error, {:already_started, pid}} ->
        Logger.info("Claude session already exists: #{session_name}")
        {:ok, pid}
        
      {:error, reason} ->
        Logger.error("Failed to start Claude session #{session_name}: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc "Stop a Claude session"
  def stop_session(session_name) do
    case Registry.lookup(AshChat.ClaudeSessionRegistry, session_name) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(AshChat.ClaudeSessionDynamicSupervisor, pid)
        
      [] ->
        {:error, :not_found}
    end
  end
  
  @doc "List all active sessions"
  def list_sessions do
    Registry.select(AshChat.ClaudeSessionRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
    |> Enum.map(fn {session_name, pid} ->
      try do
        status = GenServer.call(pid, :status, 1000)
        {session_name, status}
      catch
        :exit, _ -> {session_name, :dead}
      end
    end)
  end
  
  @doc "Get session info"
  def session_info(session_name) do
    case Registry.lookup(AshChat.ClaudeSessionRegistry, session_name) do
      [{pid, _}] ->
        try do
          GenServer.call(pid, :info, 1000)
        catch
          :exit, reason -> {:error, reason}
        end
        
      [] ->
        {:error, :not_found}
    end
  end
end