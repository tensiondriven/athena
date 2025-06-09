defmodule ClaudeCollector.Statistics do
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def increment_processed do
    GenServer.cast(__MODULE__, :increment_processed)
  end

  def increment_published(count) do
    GenServer.cast(__MODULE__, {:increment_published, count})
  end

  def increment_failed(count) do
    GenServer.cast(__MODULE__, {:increment_failed, count})
  end

  @impl true
  def init(_) do
    state = %{
      events_processed: 0,
      events_published: 0,
      events_failed: 0,
      started_at: DateTime.utc_now()
    }
    
    Logger.info("Claude Chat Collector Statistics started")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    uptime_seconds = DateTime.diff(DateTime.utc_now(), state.started_at)
    
    stats = Map.put(state, :uptime_seconds, uptime_seconds)
    {:reply, stats, state}
  end

  @impl true
  def handle_cast(:increment_processed, state) do
    new_state = Map.update!(state, :events_processed, &(&1 + 1))
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:increment_published, count}, state) do
    new_state = Map.update!(state, :events_published, &(&1 + count))
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:increment_failed, count}, state) do
    new_state = Map.update!(state, :events_failed, &(&1 + count))
    {:noreply, new_state}
  end
end