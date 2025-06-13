defmodule AshChat.Setup do
  @moduledoc """
  Clean data setup and reset functionality for quick iteration
  """

  alias AshChat.Resources.{User, Room, AgentCard, Profile, SystemPrompt, Message, RoomMembership, AgentMembership}

  def reset_demo_data() do
    # Only allow in development environment
    if Mix.env() != :dev do
      raise "reset_demo_data() can only be run in development environment!"
    end
    
    # Clear all data by destroying all resources
    User.read!() |> Enum.each(&User.destroy!/1)
    Room.read!() |> Enum.each(&Room.destroy!/1)
    AgentCard.read!() |> Enum.each(&AgentCard.destroy!/1)
    Profile.read!() |> Enum.each(&Profile.destroy!/1)
    SystemPrompt.read!() |> Enum.each(&SystemPrompt.destroy!/1)
    Message.read!() |> Enum.each(&Message.destroy!/1)
    RoomMembership.read!() |> Enum.each(&RoomMembership.destroy!/1)
    AgentMembership.read!() |> Enum.each(&AgentMembership.destroy!/1)
    
    # Create clean minimal data
    create_demo_data()
  end

  def create_demo_data() do
    seed_data = load_seed_config()
    
    # 1. Create user
    jonathan = User.create!(seed_data["user"])

    # 2. Create profile (auto-detect OpenRouter vs Ollama)
    use_openrouter = Application.get_env(:ash_chat, :use_openrouter, false)
    openrouter_key = Application.get_env(:langchain, :openrouter_key)

    profile_config = if use_openrouter && openrouter_key do
      seed_data["profiles"]["openrouter"]
      |> Map.put("api_key", openrouter_key)
    else
      seed_data["profiles"]["ollama"]
      |> Map.put("url", expand_env_vars(seed_data["profiles"]["ollama"]["url"]))
    end

    profile = Profile.create!(profile_config)

    # 3. Create system prompt
    system_prompt_config = seed_data["system_prompt"]
    |> Map.put("profile_id", profile.id)
    
    system_prompt = SystemPrompt.create!(system_prompt_config)

    # 4. Create agent card
    agent_card_config = seed_data["agent_card"]
    |> Map.put("system_prompt_id", system_prompt.id)
    
    agent_card = AgentCard.create!(agent_card_config)

    # 5. Create room
    room = Room.create!(seed_data["room"])

    # 6. Add Jonathan to the room
    RoomMembership.create!(%{
      user_id: jonathan.id,
      room_id: room.id,
      role: seed_data["memberships"]["room_admin_role"]
    })

    # 7. Add the agent to the room
    AgentMembership.create!(%{
      agent_card_id: agent_card.id,
      room_id: room.id,
      role: seed_data["memberships"]["agent_role"],
      auto_respond: seed_data["memberships"]["agent_auto_respond"]
    })

    _backend_info = if profile.provider == "openrouter" do
      "OpenRouter (Cloud)"
    else
      "Local Ollama"
    end

    %{
      profile: profile,
      system_prompt: system_prompt,
      user: jonathan,
      agent_card: agent_card,
      room: room,
      demo_summary: """
      Clean minimal data created!

      👤 User: #{jonathan.display_name}
      🔧 Profile: #{profile.name} (#{profile.provider})
      📝 System Prompt: #{system_prompt.name}
      🤖 Agent: #{agent_card.name}
      🏠 Room: #{room.title}

      Ready to use! Visit /chat to start chatting.
      """
    }
  end

  def get_default_profile() do
    case Profile.read() do
      {:ok, profiles} ->
        default = Enum.find(profiles, & &1.is_default) || List.first(profiles)
        {:ok, default}
      error -> error
    end
  end

  def quick_test() do
    IO.puts("🧪 Quick test of multi-user system:")
    
    users = User.read!()
    IO.puts("👥 Users: #{length(users)}")
    Enum.each(users, &IO.puts("  - #{&1.display_name}"))
    
    rooms = Room.read!()
    IO.puts("\n🏠 Rooms: #{length(rooms)}")
    Enum.each(rooms, &IO.puts("  - #{&1.title}"))
    
    memberships = RoomMembership.read!()
    IO.puts("\n🔗 Room Memberships: #{length(memberships)}")
    
    agent_cards = AgentCard.read!()
    IO.puts("\n🤖 Agent Cards: #{length(agent_cards)}")
    Enum.each(agent_cards, &IO.puts("  - #{&1.name}"))
    
    IO.puts("\n✅ System operational!")
  end

  defp load_seed_config() do
    seed_file = Path.join(Application.app_dir(:ash_chat), "../../config/seed.yaml")
    
    case YamlElixir.read_from_file(seed_file) do
      {:ok, data} -> data
      {:error, _} ->
        # Fallback if YAML not available
        %{
          "user" => %{
            "name" => "Jonathan",
            "email" => "jonathan@athena.local", 
            "display_name" => "Jonathan",
            "avatar_url" => "https://api.dicebear.com/7.x/avataaars/svg?seed=Jonathan",
            "preferences" => %{"theme" => "system", "notification_level" => "all"}
          },
          "profiles" => %{
            "openrouter" => %{
              "name" => "OpenRouter (Cloud)",
              "provider" => "openrouter",
              "url" => "https://openrouter.ai/api/v1",
              "model" => "qwen/qwen-2.5-72b-instruct",
              "is_default" => true
            },
            "ollama" => %{
              "name" => "Local Ollama",
              "provider" => "ollama",
              "url" => "http://10.1.2.200:11434",
              "model" => "qwen2.5:latest",
              "is_default" => true
            }
          },
          "system_prompt" => %{
            "name" => "Helpful Assistant",
            "content" => "You are a helpful, friendly assistant. Always respond with enthusiasm and try to be as helpful as possible. Keep responses concise but informative.",
            "description" => "A friendly and helpful AI assistant for general conversations",
            "is_active" => true
          },
          "agent_card" => %{
            "name" => "Helpful Assistant",
            "description" => "A friendly and helpful AI assistant",
            "model_preferences" => %{"temperature" => 0.7, "max_tokens" => 500},
            "available_tools" => [],
            "context_settings" => %{"history_limit" => 20, "include_room_metadata" => true},
            "is_default" => true,
            "add_to_new_rooms" => true
          },
          "room" => %{"title" => "General Chat"},
          "memberships" => %{
            "room_admin_role" => "admin",
            "agent_role" => "participant", 
            "agent_auto_respond" => true
          }
        }
    end
  end

  defp expand_env_vars(value) when is_binary(value) do
    # Simple ${VAR:default} expansion
    Regex.replace(~r/\$\{([^:}]+):([^}]+)\}/, value, fn _, var, default ->
      System.get_env(var, default)
    end)
  end
  defp expand_env_vars(value), do: value
end