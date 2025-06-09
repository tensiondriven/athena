defmodule AshChatWeb.EventDashboardLive do
  use AshChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time event broadcasts
      Phoenix.PubSub.subscribe(AshChat.PubSub, "events")
    end

    {:ok, 
     socket
     |> assign(search_query: "", selected_event_type: "")
     |> load_events()}
  end

  @impl true
  def handle_info({:new_event, event}, socket) do
    # Add the new event to the front of the list and update stats
    events = [event | socket.assigns.events] |> Enum.take(20)
    total_count = socket.assigns.total_count + 1
    
    # Update event type counts
    event_types = update_event_type_counts(socket.assigns.event_types, event.event_type)
    
    {:noreply, assign(socket, 
      events: events, 
      total_count: total_count,
      event_types: event_types,
      last_updated: DateTime.utc_now()
    )}
  end

  defp update_event_type_counts(current_types, new_event_type) do
    # Check if this is a new event type (excluding system events to prevent recursion)
    is_new_type = not Enum.any?(current_types, fn {type, _} -> type == new_event_type end)
    
    updated_types = current_types
    |> Enum.map(fn {type, count} ->
      if type == new_event_type do
        {type, count + 1}
      else
        {type, count}
      end
    end)
    |> then(fn types ->
      # If the event type doesn't exist, add it
      if is_new_type do
        [{new_event_type, 1} | types]
      else
        types
      end
    end)
    |> Enum.sort_by(fn {_type, count} -> count end, :desc)
    
    # Create system event for new event type discovery (but not for system events themselves)
    if is_new_type && !String.starts_with?(new_event_type, "system.") do
      create_event_type_discovered_event(new_event_type)
    end
    
    updated_types
  end

  defp create_event_type_discovered_event(discovered_event_type) do
    Task.start(fn ->
      try do
        event_params = %{
          timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
          event_type: "system.event_type_discovered",
          source_id: "ash_chat_event_system",
          confidence: 1.0,
          description: "New event type discovered in the system",
          metadata: %{
            "discovered_event_type" => discovered_event_type,
            "discovery_timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "system_version" => "1.0.0"
          },
          validation_errors: nil
        }
        
        event = AshChat.Resources.Event.create_from_collector!(event_params)
        
        # Broadcast the new event
        Phoenix.PubSub.broadcast(
          AshChat.PubSub, 
          "events", 
          {:new_event, event}
        )
      rescue
        error ->
          require Logger
          Logger.error("Failed to create event type discovery event: #{inspect(error)}")
      end
    end)
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, load_events(socket)}
  end

  @impl true
  def handle_event("select_event", %{"event_id" => event_id}, socket) do
    {:noreply, assign(socket, selected_event_id: event_id)}
  end

  @impl true
  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_event_id: nil)}
  end

  @impl true
  def handle_event("toggle_json", %{"event_id" => event_id}, socket) do
    expanded = socket.assigns.expanded_events
    
    new_expanded = if MapSet.member?(expanded, event_id) do
      MapSet.delete(expanded, event_id)
    else
      MapSet.put(expanded, event_id)
    end

    {:noreply, assign(socket, expanded_events: new_expanded)}
  end

  @impl true
  def handle_event("search", %{"search_query" => query}, socket) do
    {:noreply, 
     socket
     |> assign(search_query: query, selected_event_id: nil)
     |> load_events()}
  end

  @impl true
  def handle_event("filter_by_type", %{"event_type" => event_type}, socket) do
    {:noreply, 
     socket
     |> assign(selected_event_type: event_type, selected_event_id: nil)
     |> load_events()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, 
     socket
     |> assign(search_query: "", selected_event_type: "", selected_event_id: nil)
     |> load_events()}
  end

  defp load_events(socket) do
    require Logger
    
    try do
      Logger.info("Loading events from Ash resource...")
      all_events = AshChat.Resources.Event.recent!(%{limit: 200})
      Logger.info("Loaded #{length(all_events)} events successfully")
      
      # Apply filters
      filtered_events = all_events
      |> filter_by_search(socket.assigns[:search_query] || "")
      |> filter_by_event_type(socket.assigns[:selected_event_type] || "")
      |> Enum.take(50)
      
      total_count = AshChat.Resources.Event.read!() |> length()
      Logger.info("Total event count: #{total_count}")
      
      # Get event type counts from all events (not filtered)
      event_types = all_events
      |> Enum.group_by(& &1.event_type)
      |> Enum.map(fn {type, events} -> {type, length(events)} end)
      |> Enum.sort_by(fn {_type, count} -> count end, :desc)

      socket
      |> assign(
        events: filtered_events,
        all_event_types: event_types,
        total_count: total_count,
        filtered_count: length(filtered_events),
        expanded_events: socket.assigns[:expanded_events] || MapSet.new(),
        selected_event_id: socket.assigns[:selected_event_id],
        last_updated: DateTime.utc_now()
      )
    rescue
      error ->
        Logger.error("Failed to load events: #{inspect(error)}")
        assign(socket, 
          events: [], 
          all_event_types: [],
          total_count: 0,
          filtered_count: 0,
          expanded_events: MapSet.new(),
          selected_event_id: nil,
          search_query: socket.assigns[:search_query] || "",
          selected_event_type: socket.assigns[:selected_event_type] || "",
          last_updated: DateTime.utc_now()
        )
    end
  end

  defp filter_by_search(events, ""), do: events
  defp filter_by_search(events, query) do
    query = String.downcase(query)
    Enum.filter(events, fn event ->
      String.contains?(String.downcase(event.event_type), query) or
      String.contains?(String.downcase(event.source_id), query) or
      (event.description && String.contains?(String.downcase(event.description), query)) or
      metadata_contains?(event.metadata, query)
    end)
  end

  defp filter_by_event_type(events, ""), do: events
  defp filter_by_event_type(events, event_type) do
    Enum.filter(events, fn event -> event.event_type == event_type end)
  end

  defp metadata_contains?(metadata, query) when is_map(metadata) do
    metadata
    |> Jason.encode!()
    |> String.downcase()
    |> String.contains?(query)
  rescue
    _ -> false
  end

  defp format_timestamp(timestamp) do
    timestamp
    |> DateTime.truncate(:second)
    |> DateTime.to_string()
  end

  defp format_json(data) do
    Jason.encode!(data, pretty: true)
  end

  defp time_ago(timestamp) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, timestamp, :second)
    
    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  defp event_type_color(event_type) do
    case event_type do
      "system." <> _ -> "bg-purple-400"
      "user." <> _ -> "bg-blue-400" 
      "collector." <> _ -> "bg-green-400"
      "analytics." <> _ -> "bg-yellow-400"
      "monitoring." <> _ -> "bg-red-400"
      "payment." <> _ -> "bg-emerald-400"
      "security." <> _ -> "bg-orange-400"
      "file_collector_startup" -> "bg-green-500"
      _ -> "bg-gray-400"
    end
  end

end