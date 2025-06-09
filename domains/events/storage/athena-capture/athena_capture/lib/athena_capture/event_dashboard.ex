defmodule AthenaCapture.EventDashboard do
  @moduledoc """
  Simple dashboard showing real-time event activity.
  
  Provides visual feedback for the "bell on a string" - showing event counts,
  types per minute, and activity indicators as events flow through the system.
  """
  
  use GenServer
  require Logger
  
  defstruct [
    :event_counts,
    :recent_events,
    :start_time,
    :last_display
  ]
  
  @display_interval 10_000  # Update display every 10 seconds
  @recent_window 300_000    # Keep 5 minutes of recent events
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def record_event(type, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:event, type, metadata, DateTime.utc_now()})
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def init(_opts) do
    Logger.info("🔔 Event Dashboard starting - your bell on a string!")
    
    state = %__MODULE__{
      event_counts: %{},
      recent_events: [],
      start_time: DateTime.utc_now(),
      last_display: DateTime.utc_now()
    }
    
    schedule_display()
    {:ok, state}
  end
  
  def handle_cast({:event, type, metadata, timestamp}, state) do
    # Update counters
    new_counts = Map.update(state.event_counts, type, 1, &(&1 + 1))
    
    # Add to recent events (keep only recent window)
    cutoff = DateTime.add(timestamp, -@recent_window, :millisecond)
    new_recent = [{type, metadata, timestamp} | state.recent_events]
                 |> Enum.filter(fn {_t, _m, ts} -> DateTime.compare(ts, cutoff) == :gt end)
    
    new_state = %{state | 
      event_counts: new_counts,
      recent_events: new_recent
    }
    
    # Ring the bell! 🔔
    Logger.info("🔔 #{type} event captured")
    
    {:noreply, new_state}
  end
  
  def handle_call(:get_stats, _from, state) do
    uptime = DateTime.diff(DateTime.utc_now(), state.start_time, :second)
    recent_count = length(state.recent_events)
    
    stats = %{
      total_events: Enum.sum(Map.values(state.event_counts)),
      event_types: Map.keys(state.event_counts),
      recent_events: recent_count,
      events_per_minute: if(uptime > 0, do: (recent_count / (uptime / 60)) |> Float.round(2), else: 0),
      uptime_seconds: uptime,
      event_counts: state.event_counts
    }
    
    {:reply, stats, state}
  end
  
  def handle_info(:display_update, state) do
    display_activity_summary(state)
    schedule_display()
    {:noreply, %{state | last_display: DateTime.utc_now()}}
  end
  
  defp schedule_display do
    Process.send_after(self(), :display_update, @display_interval)
  end
  
  defp display_activity_summary(state) do
    uptime = DateTime.diff(DateTime.utc_now(), state.start_time, :second)
    total = Enum.sum(Map.values(state.event_counts))
    recent = length(state.recent_events)
    
    if total > 0 do
      rate = if uptime > 60, do: (recent / (uptime / 60)) |> Float.round(1), else: 0
      
      Logger.info("""
      
      📊 Event Dashboard (#{format_uptime(uptime)})
      ═══════════════════════════════════════════
      🔔 Total Events: #{total}
      📈 Events/min:   #{rate}
      ⏱️  Recent (5m):  #{recent}
      
      📋 Event Types:
      #{format_event_types(state.event_counts)}
      ═══════════════════════════════════════════
      """)
    else
      Logger.info("📊 Event Dashboard (#{format_uptime(uptime)}) - Waiting for events... 🔔")
    end
  end
  
  defp format_uptime(seconds) when seconds < 60, do: "#{seconds}s"
  defp format_uptime(seconds) when seconds < 3600, do: "#{div(seconds, 60)}m #{rem(seconds, 60)}s"
  defp format_uptime(seconds), do: "#{div(seconds, 3600)}h #{div(rem(seconds, 3600), 60)}m"
  
  defp format_event_types(counts) do
    counts
    |> Enum.sort_by(fn {_type, count} -> count end, :desc)
    |> Enum.map(fn {type, count} -> "   #{type}: #{count}" end)
    |> Enum.join("\n")
  end
end