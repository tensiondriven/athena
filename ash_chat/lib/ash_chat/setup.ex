defmodule AshChat.Setup do
  @moduledoc """
  Demo data setup and reset functionality for quick iteration
  """

  alias AshChat.Resources.{User, Room, AgentCard, Profile, Message, RoomMembership}

  def reset_demo_data() do
    # Clear all data by destroying all resources
    User.read!() |> Enum.each(&User.destroy!/1)
    Room.read!() |> Enum.each(&Room.destroy!/1)
    AgentCard.read!() |> Enum.each(&AgentCard.destroy!/1)
    Profile.read!() |> Enum.each(&Profile.destroy!/1)
    Message.read!() |> Enum.each(&Message.destroy!/1)
    RoomMembership.read!() |> Enum.each(&RoomMembership.destroy!/1)
    
    # Create demo data
    create_demo_data()
  end

  def create_demo_data() do
    # Create demo profiles
    ollama_profile = Profile.create!(%{
      name: "Local Ollama",
      provider: "ollama",
      url: System.get_env("OLLAMA_URL", "http://localhost:11434"),
      model: "llama3.2:latest",
      is_default: true
    })

    # Create demo users
    alice = User.create!(%{
      name: "Alice",
      email: "alice@example.com",
      display_name: "Alice (Demo User)",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Alice"
    })

    bob = User.create!(%{
      name: "Bob",
      email: "bob@example.com", 
      display_name: "Bob (Demo User)",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Bob"
    })

    # Create demo agent cards
    helpful_assistant = AgentCard.create!(%{
      name: "Helpful Assistant",
      system_message: "You are a helpful, friendly assistant. Always respond with enthusiasm and try to be as helpful as possible. Keep responses concise but informative.",
      model_preferences: %{
        temperature: 0.7,
        max_tokens: 500
      },
      available_tools: [],
      context_settings: %{
        history_limit: 20,
        include_room_metadata: true
      }
    })

    creative_writer = AgentCard.create!(%{
      name: "Creative Writer", 
      system_message: "You are a creative writing assistant. Help users craft stories, poems, and creative content. Be imaginative and inspiring while offering constructive feedback.",
      model_preferences: %{
        temperature: 0.9,
        max_tokens: 800
      },
      available_tools: [],
      context_settings: %{
        history_limit: 30,
        include_room_metadata: false
      }
    })

    # Create demo rooms
    general_room = Room.create!(%{
      title: "General Chat",
      agent_card_id: helpful_assistant.id
    })

    creative_room = Room.create!(%{
      title: "Creative Writing Workshop",
      agent_card_id: creative_writer.id
    })

    # Sub-room example
    story_room = Room.create!(%{
      title: "Story Collaboration",
      parent_room_id: creative_room.id,
      agent_card_id: creative_writer.id
    })

    # Create room memberships
    RoomMembership.create!(%{
      user_id: alice.id,
      room_id: general_room.id,
      role: "admin"
    })

    RoomMembership.create!(%{
      user_id: bob.id,
      room_id: general_room.id,
      role: "member"
    })

    RoomMembership.create!(%{
      user_id: alice.id,
      room_id: creative_room.id,
      role: "moderator"
    })

    RoomMembership.create!(%{
      user_id: alice.id,
      room_id: story_room.id,
      role: "admin"
    })

    # Create some demo messages
    Message.create_text_message!(%{
      room_id: general_room.id,
      content: "Welcome to the demo chat! This is Alice testing the multi-user system.",
      role: :user,
      user_id: alice.id
    })

    Message.create_text_message!(%{
      room_id: general_room.id,
      content: "Hello Alice! Great to see the new multi-user features working. The room hierarchy looks promising!",
      role: :user,
      user_id: bob.id
    })

    Message.create_text_message!(%{
      room_id: creative_room.id,
      content: "I'd like to start a collaborative story about time travel. Any ideas for an opening scene?",
      role: :user,
      user_id: alice.id
    })

    %{
      profiles: [ollama_profile],
      users: [alice, bob],
      agent_cards: [helpful_assistant, creative_writer],
      rooms: [general_room, creative_room, story_room],
      demo_summary: """
      Demo data created successfully!
      
      👥 Users: Alice (admin), Bob (member)
      🤖 Agent Cards: Helpful Assistant, Creative Writer
      🏠 Rooms: General Chat, Creative Writing Workshop, Story Collaboration (sub-room)
      💬 Sample messages in each room
      ⚙️  Default Ollama profile configured
      
      Try testing:
      - User.read!() |> IO.inspect()
      - Room.read!() |> IO.inspect()
      - AgentCard.read!() |> IO.inspect()
      - RoomMembership.read!() |> IO.inspect()
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
end