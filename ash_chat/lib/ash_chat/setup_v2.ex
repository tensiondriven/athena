defmodule AshChat.SetupV2 do
  @moduledoc """
  Version 2 of setup using the new Companion model.
  Loads all companion configurations from YAML.
  """

  alias AshChat.Resources.{User, Room, Companion, Message, RoomMembership}
  require Logger

  def reset_demo_data() do
    # Only allow in development environment
    if Mix.env() != :dev do
      raise "reset_demo_data() can only be run in development environment!"
    end
    
    # Clear all data
    clear_all_data()
    
    # Create fresh data
    create_demo_data()
  end

  defp clear_all_data() do
    # Clear in dependency order
    Message.read!() |> Enum.each(&Message.destroy!/1)
    RoomMembership.read!() |> Enum.each(&RoomMembership.destroy!/1)
    Room.read!() |> Enum.each(&Room.destroy!/1)
    Companion.read!() |> Enum.each(&Companion.destroy!/1)
    User.read!() |> Enum.each(&User.destroy!/1)
  end

  def create_demo_data() do
    # Load configurations
    companions_config = load_companions_yaml()
    
    # 1. Create user
    jonathan = User.create!(%{
      name: "Jonathan",
      email: "jonathan@athena.local",
      display_name: "Jonathan",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Jonathan",
      preferences: %{"theme" => "system", "notification_level" => "all"}
    })
    
    # 2. Create all companions from YAML
    companions = create_companions(companions_config["companions"])
    
    # 3. Create rooms
    coffee_chat = Room.create!(%{
      title: "Coffee Chat",
      description: "Casual conversations over virtual coffee"
    })
    
    tech_room = Room.create!(%{
      title: "Technical Help",
      description: "Get help with programming and technical questions"
    })
    
    # 4. Add user to rooms
    RoomMembership.create!(%{
      user_id: jonathan.id,
      room_id: coffee_chat.id,
      role: "admin"
    })
    
    RoomMembership.create!(%{
      user_id: jonathan.id,
      room_id: tech_room.id,
      role: "admin"
    })
    
    # 5. Add default companions to rooms
    maya = Enum.find(companions, & &1.name == "Maya")
    coda = Enum.find(companions, & &1.name == "Coda")
    
    if maya do
      add_companion_to_room(maya, coffee_chat)
    end
    
    if coda do
      add_companion_to_room(coda, tech_room)
    end
    
    # Return summary
    %{
      user: jonathan,
      companions: companions,
      rooms: [coffee_chat, tech_room],
      demo_summary: """
      Demo data created!

      👤 User: #{jonathan.display_name}
      
      🤝 Companions: #{length(companions)}
      #{companions |> Enum.map(& "  - #{&1.name} (#{&1.companion_type})") |> Enum.join("\n")}
      
      🏠 Rooms:
        - #{coffee_chat.title} (with #{maya && maya.name || "no companion"})
        - #{tech_room.title} (with #{coda && coda.name || "no companion"})

      Ready to chat! Visit http://localhost:4000
      """
    }
  end

  defp create_companions(companion_configs) do
    Enum.map(companion_configs, fn config ->
      # Expand environment variables
      expanded_config = config
      |> Map.update("endpoint", nil, &expand_env_vars/1)
      |> Map.update("api_key", nil, &expand_env_vars/1)
      
      # Convert string keys to atoms and filter valid attributes
      attrs = convert_to_atom_keys(expanded_config)
      
      case Companion.create(attrs) do
        {:ok, companion} ->
          Logger.info("Created companion: #{companion.name}")
          companion
        {:error, error} ->
          Logger.error("Failed to create companion #{config["name"]}: #{inspect(error)}")
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp add_companion_to_room(companion, room) do
    # Using the existing AgentMembership for now
    # TODO: Rename to CompanionMembership
    AshChat.Resources.AgentMembership.create!(%{
      agent_card_id: companion.id,  # This will need to be updated
      room_id: room.id,
      role: "participant",
      auto_respond: companion.auto_respond
    })
  rescue
    _ ->
      Logger.warn("Could not add companion #{companion.name} to room #{room.title}")
  end

  defp load_companions_yaml() do
    config_file = Path.join(Application.app_dir(:ash_chat), "../../config/companions.yaml")
    
    case YamlElixir.read_from_file(config_file) do
      {:ok, data} -> 
        data
      {:error, reason} ->
        Logger.error("Could not load companions.yaml: #{inspect(reason)}")
        %{"companions" => []}
    end
  end

  defp expand_env_vars(nil), do: nil
  defp expand_env_vars(value) when is_binary(value) do
    # Handle ${VAR:default} syntax
    Regex.replace(~r/\$\{([^:}]+):([^}]*)\}/, value, fn _, var, default ->
      System.get_env(var, default)
    end)
  end
  defp expand_env_vars(value), do: value

  defp convert_to_atom_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> 
      key = if is_binary(k), do: String.to_atom(k), else: k
      value = case v do
        m when is_map(m) -> convert_to_atom_keys(m)
        l when is_list(l) -> Enum.map(l, &maybe_atom/1)
        other -> other
      end
      {key, value}
    end)
    |> Enum.into(%{})
  end

  defp maybe_atom(str) when is_binary(str) do
    # Try to convert known capability/tool strings to atoms
    case str do
      "memory" -> :memory
      "emotion_recognition" -> :emotion_recognition
      "topic_tracking" -> :topic_tracking
      "code_analysis" -> :code_analysis
      "architecture_design" -> :architecture_design
      "debugging" -> :debugging
      "humor" -> :humor
      "emotional_support" -> :emotional_support
      "deep_reasoning" -> :deep_reasoning
      "metaphorical_thinking" -> :metaphorical_thinking
      "synthesis" -> :synthesis
      "analysis" -> :analysis
      "planning" -> :planning
      "prioritization" -> :prioritization
      other -> other
    end
  end
  defp maybe_atom(val), do: val
end