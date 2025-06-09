defmodule AshChatWeb.LiveEventsLive do
  use AshChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to chat events from collector
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AshChat.PubSub, "live_events")
    end

    socket = 
      socket
      |> assign(:events, [])
      |> assign(:message_count, 0)
      |> assign(:page_title, "Live Events")

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_event, event}, socket) do
    # Add new event to the top of the list
    updated_events = [event | socket.assigns.events] |> Enum.take(100)  # Keep last 100
    
    socket = 
      socket
      |> assign(:events, updated_events)
      |> assign(:message_count, socket.assigns.message_count + 1)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-6xl">
      <!-- Header -->
      <div class="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h1 class="text-2xl font-bold text-gray-900">Live Events Dashboard</h1>
        <p class="text-gray-600 mt-1">Real-time chat conversations and file events</p>
        
        <!-- Stats -->
        <div class="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="bg-blue-50 rounded-lg p-4">
            <div class="text-2xl font-bold text-blue-600"><%= @message_count %></div>
            <div class="text-sm text-blue-600">Total Messages</div>
          </div>
          <div class="bg-green-50 rounded-lg p-4">
            <div class="text-2xl font-bold text-green-600"><%= length(@events) %></div>
            <div class="text-sm text-green-600">Recent Events</div>
          </div>
          <div class="bg-purple-50 rounded-lg p-4">
            <div class="text-2xl font-bold text-purple-600">
              <%= if length(@events) > 0, do: "Live", else: "Waiting" %>
            </div>
            <div class="text-sm text-purple-600">Status</div>
          </div>
        </div>
      </div>

      <!-- Events Feed -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Live Events Feed</h2>
        </div>
        
        <div class="divide-y divide-gray-200 max-h-96 overflow-y-auto">
          <%= if length(@events) == 0 do %>
            <div class="px-6 py-8 text-center text-gray-500">
              <div class="text-xl mb-2">📡</div>
              <div>Waiting for events...</div>
              <div class="text-sm mt-1">Start a conversation to see messages flow in!</div>
            </div>
          <% else %>
            <%= for event <- @events do %>
              <div class="px-6 py-4 hover:bg-gray-50">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <!-- Event Header -->
                    <div class="flex items-center space-x-2 mb-2">
                      <span class={[
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        case event.event_type do
                          "claude_conversation" -> "bg-blue-100 text-blue-800"
                          "modified" -> "bg-green-100 text-green-800"
                          _ -> "bg-gray-100 text-gray-800"
                        end
                      ]}>
                        <%= event.event_type %>
                      </span>
                      <span class="text-sm text-gray-500">
                        <%= Calendar.strftime(event.timestamp, "%H:%M:%S") %>
                      </span>
                    </div>
                    
                    <!-- File Path -->
                    <div class="text-sm font-mono text-gray-600 mb-2">
                      <%= Path.basename(event.source_path) %>
                    </div>
                    
                    <!-- Content Preview -->
                    <%= if event.event_type == "claude_conversation" and event.content do %>
                      <div class="bg-gray-50 rounded-md p-3 text-sm">
                        <div class="text-gray-700 font-medium mb-1">File Content:</div>
                        <div class="text-gray-600 font-mono text-xs max-h-20 overflow-y-auto whitespace-pre-wrap">
                          <%= String.slice(event.content, 0, 300) %><%= if String.length(event.content) > 300, do: "..." %>
                        </div>
                        <div class="text-xs text-gray-500 mt-1">
                          <%= String.length(event.content) %> characters
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end