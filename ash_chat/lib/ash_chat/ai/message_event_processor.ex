defmodule AshChat.AI.MessageEventProcessor do
  @moduledoc """
  Central processor for all message events in the system.
  Handles message persistence, event generation, and agent response orchestration.
  
  This GenServer ensures that:
  - All messages generate events for the event feed
  - Agent conversations can happen autonomously
  - UI is decoupled from the core messaging logic
  """
  
  use GenServer
  require Logger
  
  alias AshChat.AI.EventGenerator
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts) do
    # Subscribe to all message events
    Phoenix.PubSub.subscribe(AshChat.PubSub, "messages")
    
    {:ok, %{
      processing: MapSet.new(),  # Track messages being processed to avoid loops
      room_workers: %{}          # Track active room conversation workers
    }}
  end
  
  # Public API
  
  def process_message(message) do
    GenServer.cast(__MODULE__, {:process_message, message})
  end
  
  # Callbacks
  
  def handle_cast({:process_message, message}, state) do
    Logger.debug("MessageEventProcessor received message: #{message.id} (role: #{message.role})")
    
    # Skip if we're already processing this message (avoid loops)
    if MapSet.member?(state.processing, message.id) do
      Logger.debug("Skipping already processing message: #{message.id}")
      {:noreply, state}
    else
      # Telemetry start
      start_time = System.monotonic_time()
      
      state = put_in(state.processing, MapSet.put(state.processing, message.id))
      
      # 1. Generate event for the event feed
      generate_message_event(message)
      
      # 2. Broadcast to UI subscribers
      Phoenix.PubSub.broadcast(
        AshChat.PubSub,
        "room:#{message.room_id}",
        {:new_message, message}
      )
      
      # 3. Trigger agent responses if this was a user or agent message
      state = if message.role in [:user, :assistant] do
        Logger.debug("Message is from #{message.role}, triggering agent responses")
        new_state = ensure_room_worker(message.room_id, state)
        send_to_room_worker(message.room_id, {:process_message, message})
        new_state
      else
        Logger.debug("Message is from #{message.role}, not triggering agent responses")
        state
      end
      
      # Telemetry end
      :telemetry.execute(
        [:ash_chat, :message_processor, :message_processed],
        %{duration: System.monotonic_time() - start_time},
        %{message_role: message.role, room_id: message.room_id}
      )
      
      # Remove from processing after a delay
      Process.send_after(self(), {:done_processing, message.id}, 100)
      
      {:noreply, state}
    end
  end
  
  def handle_info({:done_processing, message_id}, state) do
    state = put_in(state.processing, MapSet.delete(state.processing, message_id))
    {:noreply, state}
  end
  
  def handle_info({:room_worker_stopped, room_id}, state) do
    state = put_in(state.room_workers, Map.delete(state.room_workers, room_id))
    {:noreply, state}
  end
  
  # Private functions
  
  defp generate_message_event(message) do
    # Generate appropriate event based on message type
    event_type = case message.role do
      :user -> "user_message"
      :assistant -> "agent_message"  
      :system -> "system_message"
      _ -> "message"
    end
    
    # Get sender name
    sender_name = get_message_sender_name(message)
    
    # Create event
    EventGenerator.create_event(
      event_type,
      %{
        message_id: message.id,
        room_id: message.room_id,
        sender: sender_name,
        content: message.content,
        metadata: message.metadata
      }
    )
  end
  
  defp get_message_sender_name(message) do
    case message.role do
      :user ->
        case Ash.get(AshChat.Resources.User, message.user_id) do
          {:ok, user} -> user.display_name || user.name
          _ -> "Unknown User"
        end
      :assistant ->
        case message.metadata do
          %{"agent_name" => name} -> name
          _ ->
            case Ash.get(AshChat.Resources.AgentCard, message.agent_card_id) do
              {:ok, agent} -> agent.name
              _ -> "Assistant"
            end
        end
      _ -> "System"
    end
  end
  
  defp ensure_room_worker(room_id, state) do
    case Map.get(state.room_workers, room_id) do
      nil ->
        Logger.debug("Starting new room worker for room #{room_id}")
        # Start a new worker for this room using the supervisor
        case AshChat.AI.RoomConversationSupervisor.start_room_worker(room_id) do
          {:ok, pid} ->
            Logger.debug("Started room worker #{inspect(pid)} for room #{room_id}")
            Process.monitor(pid)
            put_in(state.room_workers[room_id], pid)
          {:error, {:already_started, pid}} ->
            Logger.debug("Room worker already exists #{inspect(pid)} for room #{room_id}")
            # Worker already exists, just track it
            put_in(state.room_workers[room_id], pid)
          {:error, reason} ->
            Logger.error("Failed to start room worker for #{room_id}: #{inspect(reason)}")
            state
        end
      pid ->
        Logger.debug("Room worker already tracked #{inspect(pid)} for room #{room_id}")
        state
    end
  end
  
  defp send_to_room_worker(room_id, message) do
    case Process.whereis(room_worker_name(room_id)) do
      pid when is_pid(pid) ->
        send(pid, message)
      _ ->
        Logger.warning("No room worker found for room #{room_id}")
    end
  end
  
  defp room_worker_name(room_id) do
    String.to_atom("room_worker_#{room_id}")
  end
end