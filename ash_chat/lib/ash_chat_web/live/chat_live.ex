defmodule AshChatWeb.ChatLive do
  use AshChatWeb, :live_view
  require Logger

  alias AshChat.AI.ChatAgent
  alias AshChat.Resources.{Room, User}

  @impl true
  def mount(_params, _session, socket) do
    # Load available users for demo - in production this would come from authentication
    users = load_available_users()
    current_user = case users do
      [] -> 
        # Auto-create Jonathan user if no users exist
        case create_default_user() do
          {:ok, user} -> user
          {:error, _} -> nil
        end
      [user | _] -> user # Use first available user
    end
    
    socket = 
      socket
      |> assign(:room, nil) # No room by default - user must create explicitly
      |> assign(:messages, [])
      |> assign(:current_message, "")
      |> assign(:system_prompt, "You are a helpful AI assistant.")
      |> assign(:processing, false)
      |> assign(:page_title, "AshChat")
      |> assign(:sidebar_expanded, true)
      |> assign(:rooms, load_rooms())
      |> assign(:show_hidden_rooms, false)
      |> assign(:loading_models, false)
      |> assign(:current_loaded_model, AshChat.AI.InferenceConfig.get_current_ollama_model())
      |> assign(:available_models, AshChat.AI.InferenceConfig.get_available_models("ollama"))
      |> assign(:current_model, "current")
      |> assign(:available_users, users)
      |> assign(:current_user, current_user)
      |> assign(:show_system_modal, false)
      |> assign(:editing_agent_card, false)
      |> assign(:show_agent_library, false)
      |> assign(:creating_new_agent, false)
      |> assign(:selected_template, nil)
      |> assign(:agent_memberships, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"room_id" => room_id}, _url, socket) do
    case Ash.get(Room, room_id) do
      {:ok, room} ->
        messages = ChatAgent.get_room_messages(room_id)
        
        # Check if current user is a member of this room
        is_member = if socket.assigns.current_user do
          check_room_membership(socket.assigns.current_user.id, room_id)
        else
          false
        end
        
        # Load agent memberships for this room
        agent_memberships = case AshChat.Resources.AgentMembership.for_room(%{room_id: room_id}) do
          {:ok, memberships} -> memberships
          {:error, _} -> []
        end

        socket = 
          socket
          |> assign(:room, room)
          |> assign(:messages, messages)
          |> assign(:current_model, "current")
          |> assign(:is_room_member, is_member)
          |> assign(:agent_memberships, agent_memberships)

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
    # Guard: Don't process messages if no room is selected, no user, or not a member
    cond do
      socket.assigns.room == nil ->
        {:noreply, put_flash(socket, :error, "Please select a room first")}
      socket.assigns.current_user == nil ->
        {:noreply, put_flash(socket, :error, "No user selected - please refresh the page")}
      !socket.assigns.is_room_member ->
        {:noreply, put_flash(socket, :error, "You must join the room before sending messages")}
      String.trim(content) == "" ->
        {:noreply, socket}
      true ->
        socket = assign(socket, :processing, true)
        
        # Temporarily disable automatic AI response to fix CaseClauseError
        Task.start(fn ->
          # Just send user message without AI response for now
          ChatAgent.send_text_message(
            socket.assigns.room.id,
            content,
            socket.assigns.current_user.id
          )
          
          Phoenix.PubSub.broadcast(
            AshChat.PubSub, 
            "room:#{socket.assigns.room.id}", 
            {:message_processed}
          )
        end)

        socket = 
          socket
          |> assign(:current_message, "")
          |> update_messages()

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
    
    # Auto-join the current user to the room as admin
    if socket.assigns.current_user do
      case AshChat.Resources.RoomMembership.create(%{
        user_id: socket.assigns.current_user.id,
        room_id: room.id,
        role: "admin"
      }) do
        {:ok, _membership} -> :ok
        {:error, error} -> 
          Logger.warning("Failed to auto-join user to room: #{inspect(error)}")
      end
    end
    
    socket = 
      socket
      |> assign(:room, room)
      |> assign(:messages, [])
      |> assign(:rooms, load_rooms())
      |> assign(:is_room_member, true)  # User just joined as admin
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
  
  def handle_event("delete_room", %{"room-id" => room_id}, socket) do
    case Room.destroy(room_id) do
      {:ok, _} ->
        # If we're currently in the deleted room, redirect to chat home
        socket = if socket.assigns.room && socket.assigns.room.id == room_id do
          socket
          |> assign(:room, nil)
          |> assign(:messages, [])
          |> assign(:is_room_member, false)
          |> push_navigate(to: ~p"/chat")
        else
          socket
        end
        
        socket = assign(socket, :rooms, load_rooms())
        {:noreply, put_flash(socket, :info, "Room deleted successfully")}
      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to delete room: #{inspect(error)}")}
    end
  end
  
  def handle_event("toggle_hidden_rooms", _params, socket) do
    {:noreply, assign(socket, :show_hidden_rooms, !socket.assigns.show_hidden_rooms)}
  end
  
  def handle_event("change_model", %{"model" => model}, socket) do
    {:noreply, assign(socket, :current_model, model)}
  end

  def handle_event("refresh_models", _params, socket) do
    socket = assign(socket, :loading_models, true)
    
    # Start async task to fetch models
    Task.start(fn ->
      current_loaded = AshChat.AI.InferenceConfig.get_current_ollama_model()
      available_models = AshChat.AI.InferenceConfig.get_available_models("ollama")
      
      send(self(), {:models_refreshed, current_loaded, available_models})
    end)
    
    {:noreply, socket}
  end
  
  def handle_event("reset_demo_data", _params, socket) do
    try do
      # Reset all demo data
      AshChat.Setup.reset_demo_data()
      
      # Reload everything
      users = load_available_users()
      current_user = case users do
        [] -> nil
        [user | _] -> user
      end
      
      socket = 
        socket
        |> assign(:room, nil)
        |> assign(:messages, [])
        |> assign(:rooms, load_rooms())
        |> assign(:available_users, users)
        |> assign(:current_user, current_user)
        |> assign(:is_room_member, false)
        |> push_navigate(to: ~p"/chat")
        |> put_flash(:info, "Demo data reset successfully! New rooms and users created.")
      
      {:noreply, socket}
    rescue
      error ->
        {:noreply, put_flash(socket, :error, "Failed to reset demo data: #{inspect(error)}")}
    end
  end

  def handle_event("add_user_to_room", %{"user-id" => user_id}, socket) do
    if socket.assigns.room do
      case AshChat.Resources.RoomMembership.create(%{user_id: user_id, room_id: socket.assigns.room.id, role: "member"}) do
        {:ok, _membership} ->
          {:noreply, put_flash(socket, :info, "User added to room successfully")}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add user to room")}
      end
    else
      {:noreply, put_flash(socket, :error, "No room selected")}
    end
  end

  def handle_event("join_room", _params, socket) do
    if socket.assigns.room && socket.assigns.current_user do
      case AshChat.Resources.RoomMembership.create(%{
        user_id: socket.assigns.current_user.id, 
        room_id: socket.assigns.room.id, 
        role: "member"
      }) do
        {:ok, _membership} ->
          socket = 
            socket
            |> assign(:is_room_member, true)
            |> put_flash(:info, "Welcome to the room! You can now send messages.")
          {:noreply, socket}
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to join room (you may already be a member)")}
      end
    else
      {:noreply, put_flash(socket, :error, "No room or user selected")}
    end
  end

  def handle_event("add_myself_to_room", _params, socket) do
    # Redirect to join_room for consistency
    handle_event("join_room", %{}, socket)
  end

  def handle_event("switch_user", %{"user-id" => user_id}, socket) do
    case User.get(user_id) do
      {:ok, user} ->
        {:noreply, assign(socket, :current_user, user)}
      {:error, _} ->
        {:noreply, socket}
    end
  end

  def handle_event("show_system_prompt", _params, socket) do
    {:noreply, assign(socket, :show_system_modal, true)}
  end

  def handle_event("hide_system_modal", _params, socket) do
    {:noreply, assign(socket, :show_system_modal, false)}
  end

  def handle_event("update_system_prompt", %{"system_prompt" => new_prompt}, socket) do
    socket = 
      socket
      |> assign(:system_prompt, new_prompt)
      |> assign(:show_system_modal, false)
      |> put_flash(:info, "System prompt updated")
    
    {:noreply, socket}
  end

  def handle_event("edit_agent_card", _params, socket) do
    {:noreply, assign(socket, :editing_agent_card, true)}
  end

  def handle_event("cancel_agent_edit", _params, socket) do
    {:noreply, assign(socket, :editing_agent_card, false)}
  end

  def handle_event("update_agent_card", %{"agent" => agent_params}, socket) do
    # Get the first agent membership to edit (could be enhanced to specify which agent)
    agent_memberships = socket.assigns.agent_memberships || []
    
    case List.first(agent_memberships) do
      nil ->
        {:noreply, put_flash(socket, :error, "No agents in this room to update")}
      
      agent_membership ->
          case Ash.get(AshChat.Resources.AgentCard, agent_membership.agent_card_id) do
            {:ok, agent_card} ->
              case AshChat.Resources.AgentCard.update(agent_card, %{
                name: agent_params["name"],
                description: agent_params["description"],
                system_message: agent_params["system_message"]
              }) do
                {:ok, _updated_card} ->
                  socket = 
                    socket
                    |> assign(:editing_agent_card, false)
                    |> put_flash(:info, "Agent card updated successfully")
                  {:noreply, socket}
                
                {:error, _error} ->
                  {:noreply, put_flash(socket, :error, "Failed to update agent card")}
              end
            
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Agent card not found")}
          end
    end
  end

  def handle_event("show_agent_library", _params, socket) do
    {:noreply, assign(socket, :show_agent_library, true)}
  end

  def handle_event("hide_agent_library", _params, socket) do
    {:noreply, assign(socket, :show_agent_library, false)}
  end

  def handle_event("assign_agent_to_room", %{"agent_id" => agent_id}, socket) do
    if socket.assigns.room do
      case AshChat.Resources.Room.update(socket.assigns.room, %{agent_card_id: agent_id}) do
        {:ok, updated_room} ->
          socket = 
            socket
            |> assign(:room, updated_room)
            |> assign(:show_agent_library, false)
            |> put_flash(:info, "Agent assigned to room successfully")
          {:noreply, socket}
        
        {:error, _error} ->
          {:noreply, put_flash(socket, :error, "Failed to assign agent to room")}
      end
    else
      {:noreply, put_flash(socket, :error, "No room selected")}
    end
  end

  def handle_event("show_new_agent_form", _params, socket) do
    {:noreply, assign(socket, :creating_new_agent, true)}
  end

  def handle_event("cancel_new_agent", _params, socket) do
    socket = 
      socket
      |> assign(:creating_new_agent, false)
      |> assign(:selected_template, nil)
    {:noreply, socket}
  end

  def handle_event("select_template", %{"template" => template_name}, socket) do
    {:noreply, assign(socket, :selected_template, template_name)}
  end

  def handle_event("export_agent", %{"agent_id" => agent_id}, socket) do
    case Ash.get(AshChat.Resources.AgentCard, agent_id) do
      {:ok, agent_card} ->
        export_data = %{
          name: agent_card.name,
          description: agent_card.description,
          system_message: agent_card.system_message,
          model_preferences: agent_card.model_preferences,
          context_settings: agent_card.context_settings,
          available_tools: agent_card.available_tools,
          exported_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          version: "1.0"
        }
        
        json_data = Jason.encode!(export_data, pretty: true)
        filename = "#{String.downcase(String.replace(agent_card.name, ~r/[^a-zA-Z0-9]/, "_"))}_agent.json"
        
        socket = 
          socket
          |> push_event("download", %{filename: filename, content: json_data, type: "application/json"})
          |> put_flash(:info, "Agent configuration exported successfully!")
        
        {:noreply, socket}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to export agent")}
    end
  end

  def handle_event("import_agent", %{"file_content" => file_content}, socket) do
    try do
      import_data = Jason.decode!(file_content)
      
      # Validate required fields
      required_fields = ["name", "system_message"]
      missing_fields = Enum.filter(required_fields, &(!Map.has_key?(import_data, &1)))
      
      if Enum.empty?(missing_fields) do
        case AshChat.Resources.AgentCard.create(%{
          name: import_data["name"],
          description: import_data["description"] || "",
          system_message: import_data["system_message"],
          model_preferences: import_data["model_preferences"] || %{temperature: 0.7, max_tokens: 500},
          context_settings: import_data["context_settings"] || %{history_limit: 20, include_room_metadata: true},
          available_tools: import_data["available_tools"] || []
        }) do
          {:ok, new_agent} ->
            socket = 
              socket
              |> put_flash(:info, "Agent \"#{new_agent.name}\" imported successfully!")
            
            {:noreply, socket}
          
          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to create imported agent")}
        end
      else
        {:noreply, put_flash(socket, :error, "Invalid agent file: missing #{Enum.join(missing_fields, ", ")}")}
      end
    rescue
      Jason.DecodeError ->
        {:noreply, put_flash(socket, :error, "Invalid JSON file format")}
      error ->
        {:noreply, put_flash(socket, :error, "Import failed: #{inspect(error)}")}
    end
  end

  def handle_event("create_new_agent", %{"agent" => agent_params}, socket) do
    case AshChat.Resources.AgentCard.create(%{
      name: agent_params["name"],
      description: agent_params["description"],
      system_message: agent_params["system_message"],
      model_preferences: %{
        temperature: String.to_float(agent_params["temperature"] || "0.7"),
        max_tokens: String.to_integer(agent_params["max_tokens"] || "500")
      }
    }) do
      {:ok, new_agent} ->
        # Auto-assign to current room if one exists
        socket = if socket.assigns.room do
          case AshChat.Resources.Room.update(socket.assigns.room, %{agent_card_id: new_agent.id}) do
            {:ok, updated_room} -> assign(socket, :room, updated_room)
            {:error, _} -> socket
          end
        else
          socket
        end
        
        socket = 
          socket
          |> assign(:creating_new_agent, false)
          |> assign(:show_agent_library, false)
          |> put_flash(:info, "New agent created successfully!")
        
        {:noreply, socket}
      
      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to create agent")}
    end
  end

  # Catch-all for unhandled events
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:message_processed}, socket) do
    socket = 
      socket
      |> assign(:processing, false)
      |> update_messages()

    {:noreply, socket}
  end

  def handle_info({:models_refreshed, current_loaded, available_models}, socket) do
    socket = 
      socket
      |> assign(:loading_models, false)
      |> assign(:current_loaded_model, current_loaded)
      |> assign(:available_models, available_models)
      |> assign(:current_model, "current")  # Reset to current model option
    
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
    if socket.assigns.room == nil do
      assign(socket, :messages, [])
    else
      messages = ChatAgent.get_room_messages(socket.assigns.room.id)
      assign(socket, :messages, messages)
    end
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

  defp load_available_users do
    # Load all users for demo purposes - in production this would be filtered by permissions
    case User.read() do
      {:ok, users} -> users
      {:error, _} -> []
    end
  end

  defp create_default_user do
    User.create(%{
      name: "Jonathan",
      display_name: "Jonathan", 
      email: "jonathan@athena.local",
      is_active: true,
      preferences: %{
        "theme" => "system",
        "notification_level" => "all"
      }
    })
  end

  defp check_room_membership(user_id, room_id) do
    case AshChat.Resources.RoomMembership.for_user_and_room(%{user_id: user_id, room_id: room_id}) do
      {:ok, [_membership | _]} -> true
      _ -> false
    end
  end

  defp get_agent_templates do
    [
      %{
        name: "Debug Detective",
        description: "Expert at finding and fixing bugs in code",
        system_message: "You are a debugging expert who specializes in identifying and resolving software issues. Analyze code systematically, suggest fixes, and explain the root causes of problems clearly.",
        temperature: 0.2,
        max_tokens: 800,
        category: "Development"
      },
      %{
        name: "Meeting Facilitator",
        description: "Helps organize and facilitate productive meetings",
        system_message: "You are a meeting facilitator who helps organize agendas, keep discussions on track, and ensure all participants are heard. Be diplomatic and solution-focused.",
        temperature: 0.4,
        max_tokens: 600,
        category: "Business"
      },
      %{
        name: "Learning Tutor",
        description: "Patient teacher who explains complex topics simply",
        system_message: "You are an educational tutor who breaks down complex concepts into understandable parts. Use examples, analogies, and interactive questioning to help learners grasp difficult material.",
        temperature: 0.5,
        max_tokens: 700,
        category: "Education"
      },
      %{
        name: "Project Planner",
        description: "Strategic thinker for project management and planning",
        system_message: "You are a project management expert who helps break down complex projects into manageable tasks, identifies dependencies, and creates realistic timelines.",
        temperature: 0.3,
        max_tokens: 900,
        category: "Business"
      },
      %{
        name: "Code Reviewer",
        description: "Thorough code review specialist focused on quality",
        system_message: "You are a senior code reviewer who examines code for bugs, performance issues, security vulnerabilities, and adherence to best practices. Provide constructive feedback with specific suggestions.",
        temperature: 0.1,
        max_tokens: 1000,
        category: "Development"
      },
      %{
        name: "Content Creator",
        description: "Creative assistant for blogs, social media, and marketing",
        system_message: "You are a content creation specialist who helps write engaging blog posts, social media content, and marketing copy. Focus on audience engagement and clear messaging.",
        temperature: 0.8,
        max_tokens: 800,
        category: "Creative"
      }
    ]
  end

  defp get_selected_template(nil), do: nil
  defp get_selected_template(template_name) do
    Enum.find(get_agent_templates(), &(&1.name == template_name))
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
        <div class="h-20 border-b border-gray-200 px-4 py-2">
          <!-- User Selector -->
          <div class="mb-2">
            <label class="block text-xs font-medium text-gray-700 mb-1">Current User</label>
            <select 
              phx-change="switch_user"
              name="user_id"
              class="w-full text-sm px-2 py-1 border border-gray-300 rounded focus:outline-none focus:ring-1 focus:ring-blue-500"
            >
              <%= for user <- @available_users do %>
                <option value={user.id} selected={user.id == @current_user.id}>
                  <%= user.display_name || user.name %>
                </option>
              <% end %>
            </select>
          </div>
          <!-- Rooms Header -->
          <div class="flex items-center justify-between">
            <h2 class="font-semibold text-gray-800">Rooms</h2>
            <button 
              phx-click="toggle_sidebar"
              class="p-1 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
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
          <% filtered_rooms = filter_rooms(@rooms, @show_hidden_rooms) %>
          <%= if Enum.empty?(filtered_rooms) do %>
            <!-- No Rooms Billboard -->
            <div class="text-center py-8 px-4">
              <div class="mb-4">
                <svg class="w-16 h-16 text-gray-300 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z"></path>
                </svg>
              </div>
              <h3 class="text-sm font-medium text-gray-700 mb-2">No rooms yet</h3>
              <p class="text-xs text-gray-500 mb-4">Create your first room to start chatting with AI characters</p>
              <button 
                phx-click="create_room"
                class="inline-flex items-center gap-2 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm font-medium rounded-lg transition-colors"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Create Your First Room
              </button>
            </div>
          <% else %>
            <%= for room <- filtered_rooms do %>
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
                    "text-sm font-medium flex-1",
                    if(@room && @room.id == room.id, do: "text-blue-700", else: "text-gray-700")
                  ]}>
                    <%= room.title %>
                  </span>
                  <div class="opacity-0 group-hover:opacity-100 flex gap-1">
                    <button 
                      phx-click="hide_room" 
                      phx-value-room-id={room.id}
                      class="p-1 hover:bg-gray-200 rounded transition-all"
                      title="Hide room"
                    >
                      <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"></path>
                      </svg>
                    </button>
                    <button 
                      phx-click="delete_room" 
                      phx-value-room-id={room.id}
                      class="p-1 hover:bg-red-100 rounded transition-all"
                      title="Delete room"
                      onclick="return confirm('Are you sure you want to delete this room? This action cannot be undone.')"
                    >
                      <svg class="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                      </svg>
                    </button>
                  </div>
                </div>
                <span class="text-xs text-gray-500">
                  <%= Calendar.strftime(room.created_at, "%b %d, %I:%M %p") %>
                </span>
              </div>
            <% end %>
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
          <div class="flex justify-between items-center mb-2">
            <label class="block text-sm font-medium text-gray-700">AI Model</label>
            <button 
              phx-click="refresh_models"
              class={"text-xs hover:text-blue-800 #{if @loading_models, do: "text-gray-400 cursor-not-allowed", else: "text-blue-600"}"}
              title="Refresh model list"
              disabled={@loading_models}
            >
              <%= if @loading_models do %>
                ⏳ Loading...
              <% else %>
                🔄 Refresh
              <% end %>
            </button>
          </div>
          <select 
            phx-change="change_model"
            name="model"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            disabled={@loading_models}
          >
            <!-- Current Model Option (always first) -->
            <option value="current" selected={@current_model == "current"}>
              Current Model (<%= @current_loaded_model || "None" %>)
            </option>
            
            <!-- Available Models -->
            <%= for model <- @available_models do %>
              <option value={model} selected={model == @current_model}>
                <%= model %>
              </option>
            <% end %>
          </select>
        </div>

        <!-- User Management Panel -->
        <%= if @room do %>
          <div class="p-4 border-t border-gray-200">
            <label class="block text-sm font-medium text-gray-700 mb-2">Room Membership</label>
            
            <!-- Add yourself to room button -->
            <%= if @current_user do %>
              <div class="mb-3">
                <button 
                  phx-click="add_myself_to_room"
                  class="w-full text-sm bg-green-500 text-white px-3 py-2 rounded hover:bg-green-600"
                >
                  ➕ Add Myself to Room
                </button>
              </div>
            <% end %>
            
            <!-- Add other users -->
            <div class="space-y-2">
              <label class="block text-xs font-medium text-gray-600">Add Other Users:</label>
              <%= for user <- @available_users do %>
                <div class="flex justify-between items-center">
                  <span class="text-sm"><%= user.display_name %></span>
                  <button 
                    phx-click="add_user_to_room"
                    phx-value-user-id={user.id}
                    class="text-xs bg-blue-500 text-white px-2 py-1 rounded hover:bg-blue-600"
                  >
                    Add
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
        
        <!-- Reset Panel -->
        <div class="p-4 border-t border-gray-200">
          <button 
            phx-click="reset_demo_data"
            class="w-full text-sm bg-red-500 text-white px-3 py-2 rounded hover:bg-red-600 transition-colors"
            onclick="return confirm('Are you sure you want to reset all data? This will delete all rooms, messages, and users and create fresh demo data.')"
            title="Reset all data and create fresh demo setup"
          >
            🔄 Reset Demo Data
          </button>
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
        <%= if @room do %>
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
        <% else %>
          <!-- No Room Selected Header -->
          <div class="bg-white border-b border-gray-200 px-6 py-4">
            <h1 class="text-xl font-semibold text-gray-900">Welcome to AshChat</h1>
            <p class="text-sm text-gray-500">Select or create a room to start chatting</p>
          </div>
        <% end %>

        <%= if @room do %>
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
        <% else %>
          <!-- No Room Selected Content -->
          <div class="flex-1 flex items-center justify-center bg-gray-50">
            <div class="text-center max-w-md">
              <div class="mb-6">
                <svg class="w-20 h-20 text-gray-300 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
                </svg>
              </div>
              <h2 class="text-xl font-semibold text-gray-700 mb-3">Ready to start chatting?</h2>
              <p class="text-gray-500 mb-6">Create a new room or select an existing one from the sidebar to begin your conversation with AI characters.</p>
              <button 
                phx-click="create_room"
                class="inline-flex items-center gap-2 px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white font-medium rounded-lg transition-colors"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Create New Room
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    
    <!-- System Prompt Modal -->
    <%= if @show_system_modal do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" phx-click="hide_system_modal">
        <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto" phx-click="stop_propagation">
          <div class="p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold text-gray-900">System Configuration</h2>
              <button 
                phx-click="hide_system_modal"
                class="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
            
            <!-- System Prompt Section -->
            <div class="mb-6">
              <h3 class="text-lg font-medium text-gray-900 mb-2">System Prompt</h3>
              <p class="text-sm text-gray-600 mb-3">This prompt defines how the AI should behave and respond.</p>
              <.form for={%{}} as={:system} phx-submit="update_system_prompt" class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">Current System Prompt:</label>
                  <textarea 
                    name="system_prompt"
                    rows="6"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Enter system prompt..."
                  ><%= @system_prompt %></textarea>
                </div>
                <div class="flex justify-end gap-2">
                  <button 
                    type="button"
                    phx-click="hide_system_modal"
                    class="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
                  >
                    Cancel
                  </button>
                  <button 
                    type="submit"
                    class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
                  >
                    Update Prompt
                  </button>
                </div>
              </.form>
            </div>
            
            <!-- Agent Card Section -->
            <%= if @room && @room.agent_card_id do %>
              <div class="border-t pt-6">
                <h3 class="text-lg font-medium text-gray-900 mb-2">Current Agent Card</h3>
                <p class="text-sm text-gray-600 mb-3">This room uses an AI agent with the following configuration:</p>
                
                <%= case Ash.get(AshChat.Resources.AgentCard, @room.agent_card_id) do %>
                  <% {:ok, agent_card} -> %>
                    <%= if @editing_agent_card do %>
                      <!-- Edit Mode -->
                      <.form for={%{}} as={:agent} phx-submit="update_agent_card" class="space-y-4">
                        <div>
                          <label class="block text-sm font-medium text-gray-700 mb-1">Agent Name:</label>
                          <input 
                            type="text"
                            name="agent[name]"
                            value={agent_card.name}
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-sm font-medium text-gray-700 mb-1">Description:</label>
                          <input 
                            type="text"
                            name="agent[description]"
                            value={agent_card.description || ""}
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          />
                        </div>
                        
                        <div>
                          <label class="block text-sm font-medium text-gray-700 mb-1">Agent System Message:</label>
                          <textarea 
                            name="agent[system_message]"
                            rows="4"
                            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          ><%= agent_card.system_message %></textarea>
                        </div>
                        
                        <div class="flex justify-end gap-2">
                          <button 
                            type="button"
                            phx-click="cancel_agent_edit"
                            class="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
                          >
                            Cancel
                          </button>
                          <button 
                            type="submit"
                            class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-md transition-colors"
                          >
                            Save Changes
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <!-- View Mode -->
                      <div class="bg-gray-50 rounded-lg p-4 space-y-3">
                        <div class="flex justify-between items-start">
                          <div class="flex-1 space-y-3">
                            <div>
                              <span class="font-medium text-gray-900">Name:</span>
                              <span class="ml-2 text-gray-700"><%= agent_card.name %></span>
                            </div>
                            
                            <div>
                              <span class="font-medium text-gray-900">Description:</span>
                              <span class="ml-2 text-gray-700"><%= agent_card.description || "No description" %></span>
                            </div>
                            
                            <div>
                              <span class="font-medium text-gray-900">Agent System Message:</span>
                              <div class="mt-1 p-2 bg-white rounded border text-sm text-gray-700">
                                <%= agent_card.system_message %>
                              </div>
                            </div>
                            
                            <div>
                              <span class="font-medium text-gray-900">Model Preferences:</span>
                              <div class="mt-1 text-sm text-gray-600">
                                Temperature: <%= Map.get(agent_card.model_preferences || %{}, "temperature", "default") %>,
                                Max Tokens: <%= Map.get(agent_card.model_preferences || %{}, "max_tokens", "default") %>
                              </div>
                            </div>
                            
                            <div>
                              <span class="font-medium text-gray-900">Available Tools:</span>
                              <span class="ml-2 text-gray-700">
                                <%= if Enum.empty?(agent_card.available_tools || []) do %>
                                  All tools available
                                <% else %>
                                  <%= Enum.join(agent_card.available_tools, ", ") %>
                                <% end %>
                              </span>
                            </div>
                          </div>
                          
                          <button 
                            phx-click="edit_agent_card"
                            class="ml-4 p-2 text-gray-400 hover:text-gray-600 transition-colors"
                            title="Edit agent card"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                            </svg>
                          </button>
                        </div>
                      </div>
                    <% end %>
                  <% _ -> %>
                    <div class="text-sm text-gray-500">Agent card not found or error loading</div>
                <% end %>
              </div>
            <% else %>
              <div class="border-t pt-6">
                <div class="flex justify-between items-center mb-2">
                  <h3 class="text-lg font-medium text-gray-900">No Agent Card</h3>
                  <button 
                    phx-click="show_agent_library"
                    class="px-3 py-1 bg-blue-500 hover:bg-blue-600 text-white text-sm rounded-md transition-colors"
                  >
                    Choose Agent
                  </button>
                </div>
                <p class="text-sm text-gray-600">This room doesn't have an agent card assigned. Choose from the agent library to add AI capabilities.</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
    
    <!-- Agent Library Modal -->
    <%= if @show_agent_library do %>
      <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" phx-click="hide_agent_library">
        <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[90vh] overflow-y-auto" phx-click="stop_propagation">
          <div class="p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-semibold text-gray-900">Agent Library</h2>
              <button 
                phx-click="hide_agent_library"
                class="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
            
            <p class="text-sm text-gray-600 mb-6">Choose an agent to assign to this room. Each agent has its own personality and capabilities.</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= case AshChat.Resources.AgentCard.read() do %>
                <% {:ok, agent_cards} -> %>
                  <%= for agent_card <- agent_cards do %>
                    <div class="border rounded-lg p-4 hover:bg-gray-50 transition-colors">
                      <div class="flex justify-between items-start mb-3">
                        <div>
                          <h3 class="font-medium text-gray-900"><%= agent_card.name %></h3>
                          <p class="text-sm text-gray-600"><%= agent_card.description || "No description" %></p>
                        </div>
                        
                        <button 
                          phx-click="assign_agent_to_room"
                          phx-value-agent_id={agent_card.id}
                          class="px-3 py-1 bg-blue-500 hover:bg-blue-600 text-white text-sm rounded-md transition-colors"
                        >
                          Select
                        </button>
                      </div>
                      
                      <div class="text-xs text-gray-500 mb-2">
                        <strong>System Message:</strong>
                      </div>
                      <div class="text-xs text-gray-700 bg-gray-100 p-2 rounded max-h-20 overflow-y-auto">
                        <%= agent_card.system_message %>
                      </div>
                      
                      <div class="mt-2 flex justify-between items-center">
                        <div class="text-xs text-gray-500">
                          Temp: <%= Map.get(agent_card.model_preferences || %{}, "temperature", "0.7") %>
                        </div>
                        
                        <div class="flex items-center gap-2">
                          <button 
                            phx-click="export_agent"
                            phx-value-agent_id={agent_card.id}
                            class="px-2 py-1 bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs rounded transition-colors"
                            title="Export agent configuration"
                          >
                            📤 Export
                          </button>
                          
                          <%= if agent_card.is_default do %>
                            <span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full">Default</span>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                <% {:error, _} -> %>
                  <div class="col-span-2 text-center text-gray-500">
                    <p>Unable to load agent cards</p>
                  </div>
                <% end %>
            </div>
            
            <div class="mt-6">
              <%= if @creating_new_agent do %>
                <!-- New Agent Form -->
                <div class="border-t pt-6">
                  <h3 class="text-lg font-medium text-gray-900 mb-4">Create New Agent</h3>
                  
                  <!-- Template Selection -->
                  <div class="mb-6">
                    <h4 class="text-md font-medium text-gray-800 mb-3">Quick Start Templates</h4>
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 mb-4">
                      <%= for template <- get_agent_templates() do %>
                        <button 
                          type="button"
                          phx-click="select_template"
                          phx-value-template={template.name}
                          class={[
                            "p-3 text-left border rounded-lg transition-colors cursor-pointer",
                            if(@selected_template == template.name, 
                               do: "border-blue-500 bg-blue-50", 
                               else: "border-gray-200 hover:border-gray-300 hover:bg-gray-50")
                          ]}
                        >
                          <div class="font-medium text-sm text-gray-900"><%= template.name %></div>
                          <div class="text-xs text-gray-600 mt-1"><%= template.description %></div>
                          <div class="text-xs text-blue-600 mt-1 font-medium"><%= template.category %></div>
                        </button>
                      <% end %>
                    </div>
                    <%= if @selected_template do %>
                      <div class="text-sm text-green-600 mb-3">
                        ✓ Template "<%= @selected_template %>" selected. Form will be pre-filled.
                      </div>
                    <% end %>
                  </div>
                  
                  <% selected_template = get_selected_template(@selected_template) %>
                  <.form for={%{}} as={:agent} phx-submit="create_new_agent" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Agent Name:</label>
                        <input 
                          type="text"
                          name="agent[name]"
                          value={if selected_template, do: selected_template.name, else: ""}
                          placeholder="e.g., Debug Detective"
                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                          required
                        />
                      </div>
                      
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Description:</label>
                        <input 
                          type="text"
                          name="agent[description]"
                          value={if selected_template, do: selected_template.description, else: ""}
                          placeholder="e.g., Expert at finding and fixing bugs"
                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    </div>
                    
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">System Message:</label>
                      <textarea 
                        name="agent[system_message]"
                        rows="3"
                        placeholder="You are a debugging expert who helps developers find and fix issues..."
                        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        required
                      ><%= if selected_template, do: selected_template.system_message, else: "" %></textarea>
                    </div>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Temperature (0-2):</label>
                        <input 
                          type="number"
                          name="agent[temperature]"
                          value={if selected_template, do: selected_template.temperature, else: 0.7}
                          min="0"
                          max="2"
                          step="0.1"
                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                      
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Max Tokens:</label>
                        <input 
                          type="number"
                          name="agent[max_tokens]"
                          value={if selected_template, do: selected_template.max_tokens, else: 500}
                          min="50"
                          max="2000"
                          class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    </div>
                    
                    <div class="flex justify-end gap-2">
                      <button 
                        type="button"
                        phx-click="cancel_new_agent"
                        class="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md transition-colors"
                      >
                        Cancel
                      </button>
                      <button 
                        type="submit"
                        class="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-md transition-colors"
                      >
                        Create Agent
                      </button>
                    </div>
                  </.form>
                </div>
              <% else %>
                <!-- Create New Agent Button -->
                <div class="text-center border-t pt-6">
                  <p class="text-sm text-gray-500 mb-3">Don't see the agent you need?</p>
                  <button 
                    phx-click="show_new_agent_form"
                    class="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-md transition-colors"
                  >
                    Create New Agent
                  </button>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end

