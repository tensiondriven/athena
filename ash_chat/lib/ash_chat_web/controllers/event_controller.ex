defmodule AshChatWeb.EventController do
  use AshChatWeb, :controller
  
  require Logger

  def create(conn, params) do
    try do
      # Check if this will be a new event type BEFORE creating the event
      event_type = params["type"] || params["event_type"]
      is_new_type = should_create_event_type_discovery(event_type)
      
      event = create_event_from_collector(params)
      Logger.info("Event created successfully: #{event.id}")
      
      # Create system event for new event type if needed
      if is_new_type do
        create_event_type_discovery_async(event_type)
      end
      
      # Broadcast the new event to all connected LiveViews
      Phoenix.PubSub.broadcast(
        AshChat.PubSub, 
        "events", 
        {:new_event, event}
      )
      
      # Also broadcast to live events dashboard
      Phoenix.PubSub.broadcast(
        AshChat.PubSub, 
        "live_events", 
        {:new_event, event}
      )
      
      conn
      |> put_status(:created)
      |> json(%{
        status: "success",
        event_id: event.id,
        message: "Event created successfully"
      })
    rescue
      error ->
        Logger.error("Failed to create event: #{inspect(error)}")
        
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: "Failed to create event"
        })
    end
  end

  def health(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "healthy",
      service: "ash_chat_events",
      timestamp: DateTime.utc_now()
    })
  end

  def stats(conn, _params) do
    # Get event statistics
    total_events = count_events()
    recent_events = count_recent_events()
    event_types = get_event_type_counts()
    
    conn
    |> put_status(:ok)
    |> json(%{
      total_events: total_events,
      recent_events_24h: recent_events,
      event_types: event_types,
      timestamp: DateTime.utc_now()
    })
  end

  defp create_event_from_collector(params) do
    # Map collector format to our Event resource arguments
    # The create_from_collector action takes arguments, not attributes
    event_args = %{
      timestamp: params["timestamp"],
      event_type: params["type"] || params["event_type"],
      source_id: params["source"] || params["source_id"] || "athena-collector",
      source_path: params["source_path"],
      content: params["content"],
      confidence: params["confidence"],
      description: params["description"] || "Event from #{params["source"] || "unknown"}",
      metadata: params["metadata"] || %{},
      validation_errors: params["validation_errors"]
    }

    Logger.debug("Creating event with type: #{event_args.event_type}")
    AshChat.Resources.Event.create_from_collector!(event_args)
  rescue
    error ->
      Logger.error("Error creating event: #{inspect(error)}")
      reraise error, __STACKTRACE__
  end

  defp count_events do
    try do
      AshChat.Resources.Event.read!() |> length()
    rescue
      _ -> 0
    end
  end

  defp count_recent_events do
    try do
      twenty_four_hours_ago = DateTime.utc_now() |> DateTime.add(-24, :hour)
      
      AshChat.Resources.Event.read!()
      |> Enum.filter(fn event -> 
        DateTime.compare(event.created_at, twenty_four_hours_ago) == :gt
      end)
      |> length()
    rescue
      _ -> 0
    end
  end

  defp get_event_type_counts do
    try do
      AshChat.Resources.Event.read!()
      |> Enum.group_by(& &1.event_type)
      |> Enum.map(fn {type, events} -> {type, length(events)} end)
      |> Enum.into(%{})
    rescue
      _ -> %{}
    end
  end

  defp should_create_event_type_discovery(event_type) do
    # Don't create system events for system events themselves to prevent recursion
    if String.starts_with?(event_type, "system.") do
      false
    else
      # Check if this event type already exists in our database  
      existing_types = get_event_type_counts() |> Map.keys()
      event_type not in existing_types
    end
  end

  defp create_event_type_discovery_async(discovered_event_type) do
    Logger.info("Creating system event for new event type: #{discovered_event_type}")
    
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
        
        system_event = AshChat.Resources.Event.create_from_collector!(event_params)
        Logger.info("System event created successfully: #{system_event.id}")
        
        # Broadcast the system event too
        Phoenix.PubSub.broadcast(
          AshChat.PubSub, 
          "events", 
          {:new_event, system_event}
        )
      rescue
        error ->
          Logger.error("Failed to create event type discovery event: #{inspect(error)}")
      end
    end)
  end

  defp format_errors(errors) do
    Enum.map(errors, fn
      {field, {message, _}} -> %{field: field, message: message}
      {field, message} when is_binary(message) -> %{field: field, message: message}
      error -> %{field: :unknown, message: inspect(error)}
    end)
  end
end