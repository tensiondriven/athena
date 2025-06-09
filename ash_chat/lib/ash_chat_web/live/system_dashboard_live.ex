defmodule AshChatWeb.SystemDashboardLive do
  use AshChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5000, self(), :update_stats)
    end
    
    socket = 
      socket
      |> assign(:page_title, "System Dashboard")
      |> load_system_status()

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_stats, socket) do
    {:noreply, load_system_status(socket)}
  end

  defp load_system_status(socket) do
    socket
    |> assign(:timestamp, DateTime.utc_now())
    |> assign(:components, get_component_status())
    |> assign(:data_flows, get_data_flows())
    |> assign(:external_deps, get_external_dependencies())
    |> assign(:event_stats, get_event_statistics())
  end

  defp get_component_status() do
    [
      %{
        name: "Phoenix LiveView Server",
        status: :running,
        details: "http://127.0.0.1:4000",
        events: "HTTP requests, LiveView connections"
      },
      %{
        name: "Ash Resources (Room, Message)",
        status: :active,
        details: "ETS data layer, no persistence",
        events: "CRUD operations, no events consumed yet"
      },
      %{
        name: "Room Agent (AI)",
        status: :configured,
        details: "LangChain + OpenAI GPT-4o integration",
        events: "Message processing, tool calls"
      },
      %{
        name: "Image Processor",
        status: :idle,
        details: "GenServer ready, no sources configured",
        events: "File system monitoring, URL fetching"
      },
      %{
        name: "Tool Framework",
        status: :stubbed,
        details: "Basic tools defined, AshAI integration disabled",
        events: "Tool calls from AI agent"
      },
      %{
        name: "Vector Store (Semantic Search)",
        status: :disabled,
        details: "AshAI vectorization commented out",
        events: "Embedding creation, similarity search"
      },
      %{
        name: "PubSub System",
        status: :running,
        details: "Phoenix.PubSub for real-time updates",
        events: "Chat message broadcasts"
      }
    ]
  end

  defp get_data_flows() do
    [
      %{
        from: "User (LiveView)",
        to: "Chat Agent",
        data: "Text messages, image URLs",
        status: :active
      },
      %{
        from: "Chat Agent", 
        to: "LangChain/OpenAI",
        data: "Formatted messages, tool definitions",
        status: :configured
      },
      %{
        from: "AI Response",
        to: "Ash Resources",
        data: "Assistant messages",
        status: :active
      },
      %{
        from: "Image Processor",
        to: "Chat Agent",
        data: "Discovered images",
        status: :idle
      },
      %{
        from: "PubSub",
        to: "LiveView Clients",
        data: "Real-time message updates",
        status: :active
      },
      %{
        from: "Messages",
        to: "Vector Store",
        data: "Text embeddings",
        status: :disabled
      }
    ]
  end

  defp get_external_dependencies() do
    [
      %{
        name: "OpenAI API",
        status: check_openai_key(),
        endpoint: "api.openai.com",
        purpose: "GPT-4o chat completions"
      },
      %{
        name: "Neo4j Database", 
        status: :unavailable,
        endpoint: "10.1.2.200:7474",
        purpose: "Graph storage (if needed)"
      },
      %{
        name: "HTTPoison",
        status: :missing,
        endpoint: "N/A",
        purpose: "HTTP requests for image fetching"
      },
      %{
        name: "MCP Server",
        status: :configured,
        endpoint: "Local process",
        purpose: "Question display functionality"
      }
    ]
  end

  defp get_event_statistics() do
    %{
      total_rooms: count_rooms(),
      total_messages: count_messages(),
      active_connections: 0, # TODO: Track active WebSocket connections properly
      image_processor_sources: 0,
      tool_calls_made: 0,
      events_consumed: 0  # This is the key issue - nothing consuming events yet
    }
  end

  defp check_openai_key() do
    case System.get_env("OPENAI_API_KEY") do
      nil -> :missing
      "" -> :missing
      _key -> :configured
    end
  end

  defp count_rooms() do
    try do
      case AshChat.Resources.Room.read() do
        {:ok, rooms} -> length(rooms)
        _ -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp count_messages() do
    try do
      case AshChat.Resources.Message.read() do
        {:ok, messages} -> length(messages)
        _ -> 0
      end
    rescue
      _ -> 0
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-6">
      <div class="flex justify-between items-center">
        <h1 class="text-3xl font-bold text-gray-900">System Dashboard</h1>
        <div class="text-sm text-gray-500">
          Last updated: <%= Calendar.strftime(@timestamp, "%H:%M:%S UTC") %>
        </div>
      </div>

      <!-- Key Issue Alert -->
      <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-yellow-800">Zero Events Being Consumed</h3>
            <p class="mt-2 text-sm text-yellow-700">
              No event processing is currently active. Image processor idle, vector store disabled, tool calls stubbed.
            </p>
          </div>
        </div>
      </div>

      <!-- Event Statistics -->
      <div class="bg-white shadow rounded-lg p-6">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Event Statistics</h2>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div class="text-center">
            <div class="text-2xl font-bold text-blue-600"><%= @event_stats.total_rooms %></div>
            <div class="text-sm text-gray-500">Total Rooms</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-green-600"><%= @event_stats.total_messages %></div>
            <div class="text-sm text-gray-500">Total Messages</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-purple-600"><%= @event_stats.active_connections %></div>
            <div class="text-sm text-gray-500">Active Connections</div>
          </div>
          <div class="text-center">
            <div class="text-2xl font-bold text-red-600"><%= @event_stats.events_consumed %></div>
            <div class="text-sm text-gray-500">Events Consumed</div>
          </div>
        </div>
      </div>

      <!-- System Components -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-medium text-gray-900">System Components</h2>
        </div>
        <ul class="divide-y divide-gray-200">
          <%= for component <- @components do %>
            <li class="px-6 py-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class={[
                    "h-3 w-3 rounded-full mr-3",
                    status_color(component.status)
                  ]}></div>
                  <div>
                    <h3 class="text-sm font-medium text-gray-900"><%= component.name %></h3>
                    <p class="text-sm text-gray-500"><%= component.details %></p>
                    <p class="text-xs text-gray-400">Events: <%= component.events %></p>
                  </div>
                </div>
                <span class={[
                  "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                  status_badge_color(component.status)
                ]}>
                  <%= component.status %>
                </span>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <!-- Data Flows -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-medium text-gray-900">Data Flows</h2>
        </div>
        <ul class="divide-y divide-gray-200">
          <%= for flow <- @data_flows do %>
            <li class="px-6 py-4">
              <div class="flex items-center">
                <div class="text-sm">
                  <span class="font-medium text-gray-900"><%= flow.from %></span>
                  <span class="mx-2 text-gray-400">→</span>
                  <span class="font-medium text-gray-900"><%= flow.to %></span>
                </div>
                <div class="ml-4 flex-1">
                  <p class="text-sm text-gray-500"><%= flow.data %></p>
                </div>
                <span class={[
                  "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                  status_badge_color(flow.status)
                ]}>
                  <%= flow.status %>
                </span>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <!-- External Dependencies -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-medium text-gray-900">External Dependencies</h2>
        </div>
        <ul class="divide-y divide-gray-200">
          <%= for dep <- @external_deps do %>
            <li class="px-6 py-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class={[
                    "h-3 w-3 rounded-full mr-3",
                    status_color(dep.status)
                  ]}></div>
                  <div>
                    <h3 class="text-sm font-medium text-gray-900"><%= dep.name %></h3>
                    <p class="text-sm text-gray-500"><%= dep.endpoint %></p>
                    <p class="text-xs text-gray-400"><%= dep.purpose %></p>
                  </div>
                </div>
                <span class={[
                  "inline-flex px-2 py-1 text-xs font-semibold rounded-full",
                  status_badge_color(dep.status)
                ]}>
                  <%= dep.status %>
                </span>
              </div>
            </li>
          <% end %>
        </ul>
      </div>

      <!-- Quick Actions -->
      <div class="bg-white shadow rounded-lg p-6">
        <h2 class="text-lg font-medium text-gray-900 mb-4">Quick Actions</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <a href="/chat" class="block p-4 border border-gray-200 rounded-lg hover:border-blue-300">
            <h3 class="font-medium text-gray-900">Open Chat</h3>
            <p class="text-sm text-gray-500">Start a conversation</p>
          </a>
          <button class="block p-4 border border-gray-200 rounded-lg hover:border-green-300 text-left">
            <h3 class="font-medium text-gray-900">Configure Image Sources</h3>
            <p class="text-sm text-gray-500">Add file system or URL sources</p>
          </button>
          <button class="block p-4 border border-gray-200 rounded-lg hover:border-purple-300 text-left">
            <h3 class="font-medium text-gray-900">Enable Vector Store</h3>
            <p class="text-sm text-gray-500">Activate semantic search</p>
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp status_color(:running), do: "bg-green-400"
  defp status_color(:active), do: "bg-green-400" 
  defp status_color(:configured), do: "bg-blue-400"
  defp status_color(:idle), do: "bg-yellow-400"
  defp status_color(:stubbed), do: "bg-gray-400"
  defp status_color(:disabled), do: "bg-red-400"
  defp status_color(:missing), do: "bg-red-400"
  defp status_color(:unavailable), do: "bg-red-400"

  defp status_badge_color(:running), do: "bg-green-100 text-green-800"
  defp status_badge_color(:active), do: "bg-green-100 text-green-800"
  defp status_badge_color(:configured), do: "bg-blue-100 text-blue-800"
  defp status_badge_color(:idle), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_color(:stubbed), do: "bg-gray-100 text-gray-800"
  defp status_badge_color(:disabled), do: "bg-red-100 text-red-800"
  defp status_badge_color(:missing), do: "bg-red-100 text-red-800"
  defp status_badge_color(:unavailable), do: "bg-red-100 text-red-800"
end