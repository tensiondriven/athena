# Event System Notes

## Auto-Discovery Implementation

**Key insight**: We check for new event types BEFORE creating the event to avoid timing issues:

```elixir
# In event_controller.ex
event_type = params["type"] || params["event_type"]
is_new_type = should_create_event_type_discovery(event_type)

event = create_event_from_collector(params)

if is_new_type do
  create_event_type_discovery_async(event_type)
end
```

**Recursion protection**: `String.starts_with?(event_type, "system.")` prevents infinite loops.

## LiveView State Management 

**Gotcha**: Always set ALL assigns that templates expect, even in error cases:

```elixir
# This was the missing last_updated fix:
rescue
  _error ->
    assign(socket, 
      events: [], 
      total_count: 0, 
      event_types: [], 
      expanded_events: MapSet.new(),
      selected_event_id: nil,
      last_updated: DateTime.utc_now()  # <-- Don't forget this
    )
```

## Event Color Logic

```elixir
defp event_type_color(event_type) do
  case event_type do
    "system." <> _ -> "bg-purple-400"
    "user." <> _ -> "bg-blue-400" 
    "file_collector_startup" -> "bg-green-500"  # Legacy support
    _ -> "bg-gray-400"
  end
end
```

## API Endpoints

- `POST /webhook/test` - Main event ingestion (legacy compatibility)
- `POST /api/events` - Standard event API
- `GET /api/events/stats` - Event type counts
- `GET /events` - LiveView interface

## Template Architecture

Split-panel layout: 50/50 with `flex overflow-hidden` to prevent scroll issues. Key CSS classes:
- `h-screen` on container
- `flex-1 overflow-y-auto` on scrollable sections
- `flex-shrink-0` on fixed headers

That's it. Everything else is standard Phoenix/LiveView patterns.