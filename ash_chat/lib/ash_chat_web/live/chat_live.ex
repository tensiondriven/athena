defmodule AshChatWeb.ChatLive do
  use AshChatWeb, :live_view
  require Logger

  alias AshChat.AI.ChatAgent
  alias AshChat.Resources.Room

  @impl true
  def mount(_params, _session, socket) do
    # Create a new room session
    room = ChatAgent.create_room()
    
    socket = 
      socket
      |> assign(:room, room)
      |> assign(:messages, [])
      |> assign(:current_message, "")
      |> assign(:system_prompt, "You are a helpful AI assistant.")
      |> assign(:processing, false)
      |> assign(:page_title, "Ollama Room")
      |> assign(:sidebar_expanded, true)
      |> assign(:rooms, load_rooms())
      |> assign(:show_hidden_rooms, false)
      |> assign(:available_models, ["qwen2.5:latest", "llama3.2:latest", "mistral:latest"])
      |> assign(:current_model, room.current_model || "qwen2.5:latest")

    # Subscribe to room updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AshChat.PubSub, "room:#{room.id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"room_id" => room_id}, _url, socket) do
    case Room.get(room_id) do
      {:ok, room} ->
        messages = ChatAgent.get_room_messages(room_id)
        
        socket = 
          socket
          |> assign(:room, room)
          |> assign(:messages, messages)
          |> assign(:current_model, room.current_model || "qwen2.5:latest")

        {:noreply, socket}
      
      {:error, _} ->
        {:noreply, redirect(socket, to: ~p"/chat")}
    end
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    if String.trim(content) != "" do
      socket = assign(socket, :processing, true)
      
      # Simple Ollama config with system prompt
      config = %{
        provider: "ollama",
        model: socket.assigns.current_model,
        temperature: 0.7,
        stream: false,  # Disable streaming for now
        system_prompt: socket.assigns.system_prompt
      }
      
      # Send the message asynchronously
      Task.start(fn ->
        case ChatAgent.process_message_with_system_prompt(
          socket.assigns.room.id, 
          content, 
          config
        ) do
          {:ok, _ai_message} ->
            Logger.info("Broadcasting message_processed for room #{socket.assigns.room.id}")
            Phoenix.PubSub.broadcast(
              AshChat.PubSub, 
              "room:#{socket.assigns.room.id}", 
              {:message_processed}
            )
          
          {:error, error} ->
            Logger.error("Broadcasting error for room #{socket.assigns.room.id}: #{error}")
            Phoenix.PubSub.broadcast(
              AshChat.PubSub, 
              "room:#{socket.assigns.room.id}", 
              {:error, error}
            )
        end
      end)

      socket = 
        socket
        |> assign(:current_message, "")
        |> update_messages()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("validate_message", %{"message" => %{"content" => content}}, socket) do
    {:noreply, assign(socket, :current_message, content)}
  end

  def handle_event("update_system_prompt", %{"value" => prompt}, socket) do
    {:noreply, assign(socket, :system_prompt, prompt)}
  end
  
  # New event handlers for sidebar functionality
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_expanded, !socket.assigns.sidebar_expanded)}
  end
  
  def handle_event("create_room", _params, socket) do
    room = ChatAgent.create_room()
    socket = 
      socket
      |> assign(:room, room)
      |> assign(:messages, [])
      |> assign(:rooms, load_rooms())
      |> push_navigate(to: ~p"/chat/#{room.id}")
    
    {:noreply, socket}
  end
  
  def handle_event("select_room", %{"room-id" => room_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/chat/#{room_id}")}
  end
  
  def handle_event("hide_room", %{"room-id" => room_id}, socket) do
    case Room.hide(room_id) do
      {:ok, _} ->
        socket = assign(socket, :rooms, load_rooms())
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end
  
  def handle_event("toggle_hidden_rooms", _params, socket) do
    {:noreply, assign(socket, :show_hidden_rooms, !socket.assigns.show_hidden_rooms)}
  end
  
  def handle_event("change_model", %{"model" => model}, socket) do
    # Update the room's model
    case Room.update(socket.assigns.room.id, %{current_model: model}) do
      {:ok, room} ->
        socket = 
          socket
          |> assign(:room, room)
          |> assign(:current_model, model)
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:message_processed}, socket) do
    socket = 
      socket
      |> assign(:processing, false)
      |> update_messages()

    {:noreply, socket}
  end

  def handle_info({:error, error}, socket) do
    socket = 
      socket
      |> assign(:processing, false)
      |> put_flash(:error, error)

    {:noreply, socket}
  end

  defp update_messages(socket) do
    messages = ChatAgent.get_room_messages(socket.assigns.room.id)
    assign(socket, :messages, messages)
  end
  
  # Helper functions
  defp load_rooms() do
    case Room.list_all() do
      {:ok, rooms} -> Enum.sort_by(rooms, & &1.created_at, {:desc, DateTime})
      _ -> []
    end
  end
  
  defp filter_rooms(rooms, show_hidden) do
    if show_hidden do
      rooms
    else
      Enum.filter(rooms, &(!&1.hidden))
    end
  end
  
  defp has_hidden_rooms(rooms) do
    Enum.any?(rooms, & &1.hidden)
  end
  
  defp count_hidden_rooms(rooms) do
    Enum.count(rooms, & &1.hidden)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-50">
      <!-- Sidebar -->
      <div class={[
        "bg-white border-r border-gray-200 transition-all duration-300 flex flex-col",
        if(@sidebar_expanded, do: "w-64", else: "w-0 overflow-hidden")
      ]}>
        <!-- Sidebar Header -->
        <div class="h-16 border-b border-gray-200 flex items-center justify-between px-4">
          <h2 class="font-semibold text-gray-800">Rooms</h2>
          <button 
            phx-click="toggle_sidebar"
            class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <!-- Room List -->
        <div class="flex-1 overflow-y-auto p-2">
          <!-- New Room Button -->
          <button 
            phx-click="create_room"
            class="w-full mb-2 p-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-gray-400 transition-colors flex items-center justify-center gap-2 text-gray-600 hover:text-gray-800"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
            </svg>
            New Room
          </button>
          
          <!-- Room List Items -->
          <%= for room <- filter_rooms(@rooms, @show_hidden_rooms) do %>
            <div 
              phx-click="select_room" 
              phx-value-room-id={room.id}
              class={[
                "p-3 mb-1 rounded-lg cursor-pointer transition-colors group",
                if(@room && @room.id == room.id, 
                   do: "bg-blue-50 border border-blue-200",
                   else: "hover:bg-gray-50")
              ]}
            >
              <div class="flex justify-between items-center">
                <span class={[
                  "text-sm font-medium",
                  if(@room && @room.id == room.id, do: "text-blue-700", else: "text-gray-700")
                ]}>
                  <%= room.title %>
                </span>
                <button 
                  phx-click="hide_room" 
                  phx-value-room-id={room.id}
                  class="opacity-0 group-hover:opacity-100 p-1 hover:bg-gray-200 rounded transition-all"
                >
                  <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"></path>
                  </svg>
                </button>
              </div>
              <span class="text-xs text-gray-500">
                <%= Calendar.strftime(room.created_at, "%b %d, %I:%M %p") %>
              </span>
            </div>
          <% end %>
          
          <!-- Show Hidden Toggle -->
          <%= if has_hidden_rooms(@rooms) do %>
            <button 
              phx-click="toggle_hidden_rooms"
              class="w-full mt-2 p-2 text-sm text-gray-600 hover:text-gray-800 hover:bg-gray-50 rounded-lg transition-colors"
            >
              <%= if @show_hidden_rooms do %>
                Hide Hidden Rooms
              <% else %>
                Show Hidden Rooms (<%= count_hidden_rooms(@rooms) %>)
              <% end %>
            </button>
          <% end %>
        </div>
        
        <!-- Model Selector Panel -->
        <div class="p-4 border-t border-gray-200">
          <label class="block text-sm font-medium text-gray-700 mb-2">AI Model</label>
          <select 
            phx-change="change_model"
            name="model"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <%= for model <- @available_models do %>
              <option value={model} selected={model == @current_model}>
                <%= model %>
              </option>
            <% end %>
          </select>
        </div>
      </div>
      
      <!-- Toggle Button (when collapsed) -->
      <%= if !@sidebar_expanded do %>
        <button 
          phx-click="toggle_sidebar"
          class="absolute left-0 top-4 bg-white border border-gray-200 rounded-r-lg p-2 shadow-sm hover:shadow-md transition-shadow z-10"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
          </svg>
        </button>
      <% end %>
      
      <!-- Main Content Area -->
      <div class="flex-1 flex flex-col">
        <!-- Room Header -->
        <div class="bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center">
          <div>
            <h1 class="text-xl font-semibold text-gray-900"><%= @room.title %></h1>
            <p class="text-sm text-gray-500">Using <%= @current_model %></p>
          </div>
          <div class="flex items-center gap-2">
            <button 
              phx-click="show_system_prompt"
              class="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              title="System Prompt"
            >
              <svg class="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
              </svg>
            </button>
          </div>
        </div>

        <!-- Messages Area -->
        <div class="flex-1 overflow-y-auto p-6 space-y-4 bg-gray-50">
          <%= for message <- @messages do %>
            <div class={[
              "flex",
              if(message.role == :user, do: "justify-end", else: "justify-start")
            ]}>
              <div class={[
                "max-w-xs lg:max-w-md px-4 py-2 rounded-lg",
                if(message.role == :user, 
                   do: "bg-blue-500 text-white", 
                   else: "bg-white text-gray-900 border border-gray-200")
              ]}>
                <p class="text-sm whitespace-pre-wrap"><%= message.content %></p>
                <div class={[
                  "text-xs mt-1",
                  if(message.role == :user, do: "text-blue-100", else: "text-gray-500")
                ]}>
                  <%= Calendar.strftime(message.created_at, "%I:%M %p") %>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @processing do %>
            <div class="flex justify-start">
              <div class="bg-white text-gray-900 border border-gray-200 max-w-xs lg:max-w-md px-4 py-2 rounded-lg">
                <div class="flex items-center space-x-2">
                  <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
                  <span class="text-sm">AI is thinking...</span>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <!-- Message Input -->
        <div class="bg-white border-t border-gray-200 px-6 py-4">
          <.form 
            for={%{}}
            as={:message}
            id="message-form"
            phx-submit="send_message"
            phx-change="validate_message"
            class="flex space-x-2"
          >
            <.input
              type="text"
              name="message[content]"
              value={@current_message}
              placeholder="Type your message..."
              class="flex-1"
              disabled={@processing}
            />
            
            <button
              type="submit"
              disabled={@processing or String.trim(@current_message) == ""}
              class="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-300 text-white px-4 py-2 rounded-lg transition-colors"
            >
              Send
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end