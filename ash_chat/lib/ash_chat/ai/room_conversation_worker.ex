defmodule AshChat.AI.RoomConversationWorker do
  @moduledoc """
  Worker process that manages agent conversations in a specific room.
  Handles agent response orchestration independently of any UI connections.
  """
  
  use GenServer, restart: :temporary
  require Logger
  
  alias AshChat.AI.AgentConversation
  alias AshChat.Resources.AgentMembership
  
  @idle_timeout :timer.minutes(30)  # Stop worker after 30 minutes of inactivity
  
  def start_link(opts) do
    room_id = Keyword.fetch!(opts, :room_id)
    name = String.to_atom("room_worker_#{room_id}")
    GenServer.start_link(__MODULE__, opts, name: name)
  end
  
  def init(opts) do
    room_id = Keyword.fetch!(opts, :room_id)
    
    # Set up idle timeout
    Process.send_after(self(), :check_idle, @idle_timeout)
    
    {:ok, %{
      room_id: room_id,
      last_activity: System.monotonic_time(:millisecond),
      processing_queue: :queue.new(),
      processing: false,
      agents_thinking: MapSet.new()
    }}
  end
  
  # Message handling
  
  def handle_info({:process_message, message}, state) do
    state = %{state | last_activity: System.monotonic_time(:millisecond)}
    
    # Queue the message
    state = update_in(state.processing_queue, &:queue.in(message, &1))
    
    # Start processing if not already processing
    if not state.processing do
      send(self(), :process_next_message)
      %{state | processing: true}
    else
      state
    end
    |> then(&{:noreply, &1})
  end
  
  def handle_info(:process_next_message, state) do
    case :queue.out(state.processing_queue) do
      {{:value, message}, new_queue} ->
        state = %{state | processing_queue: new_queue}
        
        # Process this message
        state = process_message_internal(message, state)
        
        # Schedule processing of next message if any
        state = if not :queue.is_empty(new_queue) do
          Process.send_after(self(), :process_next_message, 100)
          state
        else
          %{state | processing: false}
        end
        
        {:noreply, state}
        
      {:empty, _} ->
        {:noreply, %{state | processing: false}}
    end
  end
  
  def handle_info(:check_idle, state) do
    idle_time = System.monotonic_time(:millisecond) - state.last_activity
    
    if idle_time > @idle_timeout do
      Logger.info("Room worker #{state.room_id} shutting down due to inactivity")
      {:stop, :normal, state}
    else
      Process.send_after(self(), :check_idle, @idle_timeout)
      {:noreply, state}
    end
  end
  
  defp process_message_internal(message, state) do
    # Get auto-responding agents in the room
    case AgentMembership.auto_responders_for_room(%{room_id: state.room_id}) do
      {:ok, agent_memberships} when agent_memberships != [] ->
        # Broadcast thinking states
        for membership <- agent_memberships do
          with {:ok, agent_card} <- Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id) do
            thinking_msg = generate_thinking_message(agent_card.name)
            
            Phoenix.PubSub.broadcast(
              AshChat.PubSub,
              "room:#{state.room_id}",
              {:agent_thinking, agent_card.id, thinking_msg}
            )
            
            # Track thinking agents (state update handled elsewhere)
          end
        end
        
        # Process agent responses asynchronously
        Task.start(fn ->
          agent_responses = AgentConversation.process_agent_responses(
            state.room_id,
            message,
            []
          )
          
          # Send responses with delays
          for response <- agent_responses do
            if response.delay_ms > 0 do
              Process.sleep(response.delay_ms)
            end
            
            # Clear thinking state
            Phoenix.PubSub.broadcast(
              AshChat.PubSub,
              "room:#{state.room_id}",
              {:agent_done_thinking, response.agent_card.id}
            )
            
            Logger.info("Agent #{response.agent_card.name} responded autonomously in room #{state.room_id}")
          end
          
          # Clear any remaining thinking states
          responding_agent_ids = MapSet.new(agent_responses, & &1.agent_card.id)
          for membership <- agent_memberships do
            if !MapSet.member?(responding_agent_ids, membership.agent_card_id) do
              Phoenix.PubSub.broadcast(
                AshChat.PubSub,
                "room:#{state.room_id}",
                {:agent_done_thinking, membership.agent_card_id}
              )
            end
          end
        end)
        
      _ ->
        Logger.debug("No auto-responding agents in room #{state.room_id}")
    end
    
    state
  end
  
  def terminate(_reason, state) do
    # Notify the processor that we're stopping
    send(AshChat.AI.MessageEventProcessor, {:room_worker_stopped, state.room_id})
  end
  
  # Private functions
  
  defp generate_thinking_message(agent_name) do
    messages = [
      "#{agent_name} is thinking...",
      "#{agent_name} is pondering...",
      "#{agent_name} is considering a response...",
      "#{agent_name} is processing...",
      "#{agent_name} is analyzing...",
      "#{agent_name} is contemplating...",
      "#{agent_name} is formulating a response...",
      "#{agent_name} is gathering thoughts..."
    ]
    
    Enum.random(messages)
  end
end