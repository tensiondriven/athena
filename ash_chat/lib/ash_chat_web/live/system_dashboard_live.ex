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
    |> assign(:ollama_status, get_ollama_status())
  end

  defp get_component_status() do
    [
      %{
        name: "Phoenix LiveView Server",
        status: :running,
        details: "http://127.0.0.1:4000 - Core web interface working",
        events: "HTTP requests, LiveView connections"
      },
      %{
        name: "Ash Resources (Room, Message)",
        status: :active,
        details: "ETS in-memory storage - Working but not persistent",
        events: "Chat CRUD operations (basic functionality)"
      },
      %{
        name: "Chat Agent (AI Integration)",
        status: :working,
        details: "LangChain + OpenAI/Ollama - Basic chat works",
        events: "Message processing, simple responses"
      },
      %{
        name: "Image Processor",
        status: :placeholder,
        details: "GenServer skeleton exists, no real processing yet",
        events: "Future: file monitoring, URL fetching"
      },
      %{
        name: "Tool Framework",
        status: :minimal,
        details: "Basic structure, no real tools implemented",
        events: "Future: tool calls from AI agent"
      },
      %{
        name: "Vector Store & Search",
        status: :disabled,
        details: "AshAI integration exists but disabled",
        events: "Future: embeddings, semantic search"
      },
      %{
        name: "Event Processing Pipeline",
        status: :missing,
        details: "No event consumption/processing active",
        events: "Future: cross-system event processing"
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
        name: "Ollama Server",
        status: check_ollama_status(),
        endpoint: ollama_url(),
        purpose: "Local LLM hosting (#{get_ollama_model_count()} models)"
      },
      %{
        name: "Neo4j Database", 
        status: :planned,
        endpoint: "10.1.2.200:7474",
        purpose: "Graph storage (future plans, not implemented yet)"
      },
      %{
        name: "HTTPoison",
        status: :available,
        endpoint: "Built-in dependency",
        purpose: "HTTP requests (available but not actively used)"
      },
      %{
        name: "MCP Server",
        status: :experimental,
        endpoint: "Local process",
        purpose: "Question display (prototype phase)"
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

  defp ollama_url() do
    Application.get_env(:langchain, :ollama_url, "http://10.1.2.200:11434")
  end

  defp check_ollama_status() do
    try do
      case HTTPoison.get("#{ollama_url()}/api/tags", [], timeout: 3000) do
        {:ok, %HTTPoison.Response{status_code: 200}} -> :running
        _ -> :unavailable
      end
    rescue
      _ -> :unavailable
    end
  end

  defp get_ollama_model_count() do
    try do
      case HTTPoison.get("#{ollama_url()}/api/tags", [], timeout: 3000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"models" => models}} -> length(models)
            _ -> 0
          end
        _ -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp get_ollama_status() do
    try do
      running_models = get_ollama_running_models()
      recent_models = get_ollama_recent_models()
      
      %{
        running_models: running_models,
        recent_models: recent_models,
        total_models: get_ollama_model_count()
      }
    rescue
      _ -> %{running_models: [], recent_models: [], total_models: 0}
    end
  end

  defp get_ollama_running_models() do
    try do
      case HTTPoison.get("#{ollama_url()}/api/ps", [], timeout: 3000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"models" => models}} ->
              Enum.map(models, fn model ->
                %{
                  name: model["name"],
                  size_vram: format_bytes(model["size_vram"] || 0),
                  expires_at: model["expires_at"]
                }
              end)
            _ -> []
          end
        _ -> []
      end
    rescue
      _ -> []
    end
  end

  defp get_ollama_recent_models() do
    try do
      case HTTPoison.get("#{ollama_url()}/api/tags", [], timeout: 3000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"models" => models}} ->
              models
              |> Enum.sort_by(& &1["modified_at"], :desc)
              |> Enum.take(5)
              |> Enum.map(fn model ->
                %{
                  name: model["name"],
                  size: format_bytes(model["size"] || 0),
                  family: get_in(model, ["details", "family"]) || "unknown"
                }
              end)
            _ -> []
          end
        _ -> []
      end
    rescue
      _ -> []
    end
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000_000 -> "#{Float.round(bytes / 1_000_000_000, 1)}GB"
      bytes >= 1_000_000 -> "#{Float.round(bytes / 1_000_000, 1)}MB"
      bytes >= 1_000 -> "#{Float.round(bytes / 1_000, 1)}KB"
      true -> "#{bytes}B"
    end
  end
  defp format_bytes(_), do: "0B"

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

      <!-- Ollama Status -->
      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-medium text-gray-900">Ollama Server Status</h2>
        </div>
        <div class="p-6 space-y-6">
          <!-- Running Models -->
          <div>
            <h3 class="text-sm font-medium text-gray-700 mb-3">Running Models (<%= length(@ollama_status.running_models) %>)</h3>
            <%= if @ollama_status.running_models == [] do %>
              <p class="text-sm text-gray-500 italic">No models currently loaded in memory</p>
            <% else %>
              <div class="space-y-2">
                <%= for model <- @ollama_status.running_models do %>
                  <div class="flex justify-between items-center bg-green-50 border border-green-200 rounded-lg p-3">
                    <div>
                      <div class="font-medium text-green-800"><%= model.name %></div>
                      <div class="text-sm text-green-600">VRAM: <%= model.size_vram %></div>
                    </div>
                    <div class="bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-semibold">
                      LOADED
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Recent Models -->
          <div>
            <h3 class="text-sm font-medium text-gray-700 mb-3">Recent Models (Top 5)</h3>
            <div class="space-y-2">
              <%= for model <- @ollama_status.recent_models do %>
                <div class="flex justify-between items-center bg-gray-50 border border-gray-200 rounded-lg p-3">
                  <div>
                    <div class="font-medium text-gray-800"><%= model.name %></div>
                    <div class="text-sm text-gray-600"><%= model.family %> • <%= model.size %></div>
                  </div>
                  <div class="bg-gray-100 text-gray-800 px-2 py-1 rounded text-xs font-semibold">
                    AVAILABLE
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Summary Stats -->
          <div class="border-t pt-4">
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Total Models:</span>
              <span class="font-medium"><%= @ollama_status.total_models %></span>
            </div>
            <div class="flex justify-between text-sm mt-1">
              <span class="text-gray-600">Server:</span>
              <span class="font-medium">http://10.1.2.200:11434</span>
            </div>
          </div>
        </div>
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
  defp status_color(:working), do: "bg-green-400"
  defp status_color(:available), do: "bg-blue-400"
  defp status_color(:configured), do: "bg-blue-400"
  defp status_color(:experimental), do: "bg-purple-400"
  defp status_color(:planned), do: "bg-indigo-400"
  defp status_color(:minimal), do: "bg-yellow-400"
  defp status_color(:placeholder), do: "bg-gray-400"
  defp status_color(:idle), do: "bg-yellow-400"
  defp status_color(:stubbed), do: "bg-gray-400"
  defp status_color(:disabled), do: "bg-red-400"
  defp status_color(:missing), do: "bg-red-400"
  defp status_color(:unavailable), do: "bg-red-400"

  defp status_badge_color(:running), do: "bg-green-100 text-green-800"
  defp status_badge_color(:active), do: "bg-green-100 text-green-800"
  defp status_badge_color(:working), do: "bg-green-100 text-green-800"
  defp status_badge_color(:available), do: "bg-blue-100 text-blue-800"
  defp status_badge_color(:configured), do: "bg-blue-100 text-blue-800"
  defp status_badge_color(:experimental), do: "bg-purple-100 text-purple-800"
  defp status_badge_color(:planned), do: "bg-indigo-100 text-indigo-800"
  defp status_badge_color(:minimal), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_color(:placeholder), do: "bg-gray-100 text-gray-800"
  defp status_badge_color(:idle), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_color(:stubbed), do: "bg-gray-100 text-gray-800"
  defp status_badge_color(:disabled), do: "bg-red-100 text-red-800"
  defp status_badge_color(:missing), do: "bg-red-100 text-red-800"
  defp status_badge_color(:unavailable), do: "bg-red-100 text-red-800"
end