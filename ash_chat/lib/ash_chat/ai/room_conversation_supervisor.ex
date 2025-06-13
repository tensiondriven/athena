defmodule AshChat.AI.RoomConversationSupervisor do
  @moduledoc """
  Supervisor for room conversation workers.
  Uses a DynamicSupervisor to manage workers for active rooms.
  """
  
  use DynamicSupervisor
  
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
  
  @doc """
  Start a worker for a specific room
  """
  def start_room_worker(room_id) do
    spec = {AshChat.AI.RoomConversationWorker, room_id: room_id}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
  
  @doc """
  Stop a worker for a specific room
  """
  def stop_room_worker(room_id) do
    worker_name = String.to_atom("room_worker_#{room_id}")
    case Process.whereis(worker_name) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
  
  @doc """
  List all active room workers
  """
  def active_workers do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
  end
end