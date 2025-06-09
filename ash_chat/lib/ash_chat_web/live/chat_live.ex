defmodule AshChatWeb.ChatLive do
  use AshChatWeb, :live_view

  alias AshChat.AI.ChatAgent
  alias AshChat.Resources.Chat

  @impl true
  def mount(_params, _session, socket) do
    # Create a new chat session
    chat = ChatAgent.create_chat()
    
    socket = 
      socket
      |> assign(:chat, chat)
      |> assign(:messages, [])
      |> assign(:current_message, "")
      |> assign(:system_prompt, "You are a helpful AI assistant.")
      |> assign(:processing, false)
      |> assign(:page_title, "Ollama Chat")

    # Subscribe to chat updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AshChat.PubSub, "chat:#{chat.id}")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"chat_id" => chat_id}, _url, socket) do
    case Chat.read(chat_id) do
      {:ok, chat} ->
        messages = ChatAgent.get_chat_messages(chat_id)
        
        socket = 
          socket
          |> assign(:chat, chat)
          |> assign(:messages, messages)

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
        model: "llama3.2",
        temperature: 0.7,
        system_prompt: socket.assigns.system_prompt
      }
      
      # Send the message asynchronously
      Task.start(fn ->
        case ChatAgent.process_message_with_system_prompt(
          socket.assigns.chat.id, 
          content, 
          config
        ) do
          {:ok, _ai_message} ->
            Phoenix.PubSub.broadcast(
              AshChat.PubSub, 
              "chat:#{socket.assigns.chat.id}", 
              {:message_processed}
            )
          
          {:error, error} ->
            Phoenix.PubSub.broadcast(
              AshChat.PubSub, 
              "chat:#{socket.assigns.chat.id}", 
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

  def handle_event("update_system_prompt", %{"system_prompt" => prompt}, socket) do
    {:noreply, assign(socket, :system_prompt, prompt)}
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
    messages = ChatAgent.get_chat_messages(socket.assigns.chat.id)
    assign(socket, :messages, messages)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <!-- System Prompt Section -->
      <div class="mb-4 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
        <label class="block text-sm font-medium text-gray-700 mb-2">System Prompt</label>
        <textarea
          id="system-prompt-input"
          phx-blur="update_system_prompt"
          phx-hook="LocalStorage"
          data-key="system_prompt"
          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          rows="3"
          placeholder="You are a helpful AI assistant..."
        ><%= @system_prompt %></textarea>
      </div>

      <!-- Chat Section -->
      <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div class="flex flex-col h-[calc(100vh-20rem)]">
          <!-- Chat Header -->
          <div class="bg-white border-b border-gray-200 px-6 py-4">
            <h1 class="text-xl font-semibold text-gray-900">Ollama Chat</h1>
            <p class="text-sm text-gray-500">Using llama3.2</p>
          </div>

          <!-- Messages Area -->
          <div class="flex-1 overflow-y-auto p-6 space-y-4">
            <%= for message <- @messages do %>
              <div class={[
                "flex",
                if(message.role == :user, do: "justify-end", else: "justify-start")
              ]}>
                <div class={[
                  "max-w-xs lg:max-w-md px-4 py-2 rounded-lg",
                  if(message.role == :user, 
                     do: "bg-blue-500 text-white", 
                     else: "bg-gray-100 text-gray-900")
                ]}>
                  <p class="text-sm whitespace-pre-wrap"><%= message.content %></p>
                  <div class="text-xs opacity-75 mt-1">
                    <%= Calendar.strftime(message.created_at, "%I:%M %p") %>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @processing do %>
              <div class="flex justify-start">
                <div class="bg-gray-100 text-gray-900 max-w-xs lg:max-w-md px-4 py-2 rounded-lg">
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
                class="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-300 text-white px-4 py-2 rounded-lg"
              >
                Send
              </button>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end