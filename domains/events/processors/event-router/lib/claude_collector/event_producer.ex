defmodule ClaudeCollector.EventProducer do
  use GenStage
  require Logger

  def start_link(_opts) do
    GenStage.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def publish(event) do
    GenStage.cast(__MODULE__, {:publish, event})
  end

  @impl true
  def init(state) do
    Logger.info("Starting Claude Chat Event Producer")
    {:producer, %{queue: :queue.new(), demand: 0}}
  end

  @impl true
  def handle_cast({:publish, event}, state) do
    queue = :queue.in(event, state.queue)
    new_state = %{state | queue: queue}
    
    # Dispatch events if there's demand
    dispatch_events(new_state, [])
  end

  @impl true
  def handle_demand(incoming_demand, state) do
    new_demand = state.demand + incoming_demand
    new_state = %{state | demand: new_demand}
    
    dispatch_events(new_state, [])
  end

  defp dispatch_events(%{queue: queue, demand: 0} = state, events) do
    {:noreply, events, state}
  end

  defp dispatch_events(%{queue: queue, demand: demand} = state, events) do
    case :queue.out(queue) do
      {{:value, event}, new_queue} ->
        new_state = %{state | queue: new_queue, demand: demand - 1}
        dispatch_events(new_state, [event | events])
      
      {:empty, _queue} ->
        {:noreply, Enum.reverse(events), state}
    end
  end
end