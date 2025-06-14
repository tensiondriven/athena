defmodule AshChat.CharacterCard do
  @moduledoc """
  SillyTavern character card import/export functionality.
  
  Supports both V1 and V2 character card formats.
  """
  
  alias AshChat.Resources.{AgentCard, SystemPrompt, Persona}
  require Logger
  
  @doc """
  Import a character card from JSON data.
  
  Returns {:ok, agent_card} or {:error, reason}
  """
  def import_json(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, data} ->
        import_character_data(data)
      {:error, reason} ->
        {:error, "Invalid JSON: #{inspect(reason)}"}
    end
  end
  
  def import_json(_), do: {:error, "Invalid input: expected JSON string"}
  
  @doc """
  Import character data from a parsed map.
  
  Handles both V1 (direct fields) and V2 (wrapped in data field) formats.
  """
  def import_character_data(%{"spec" => "chara_card_v2", "data" => data}) do
    # V2 format
    import_v2_character(data)
  end
  
  def import_character_data(%{"name" => _} = data) do
    # V1 format or direct data
    import_v1_character(data)
  end
  
  def import_character_data(_), do: {:error, "Unrecognized character card format"}
  
  defp import_v2_character(data) do
    with {:ok, persona} <- get_or_create_default_persona(),
         {:ok, system_prompt} <- create_system_prompt(data, persona),
         {:ok, agent_card} <- create_agent_card(data, system_prompt) do
      Logger.info("Successfully imported V2 character: #{data["name"]}")
      {:ok, agent_card}
    end
  end
  
  defp import_v1_character(data) do
    with {:ok, persona} <- get_or_create_default_persona(),
         {:ok, system_prompt} <- create_system_prompt(data, persona),
         {:ok, agent_card} <- create_agent_card(data, system_prompt) do
      Logger.info("Successfully imported V1 character: #{data["name"]}")
      {:ok, agent_card}
    end
  end
  
  defp get_or_create_default_persona do
    case Persona.read!() |> Enum.find(& &1.is_default) do
      nil ->
        # Create a default persona if none exists
        Persona.create(%{
          name: "Default Import Persona",
          persona_type: "Character",
          provider: "ollama",
          model: "qwen2.5:latest",
          is_default: true,
          url: "http://10.1.2.200:11434"
        })
      persona ->
        {:ok, persona}
    end
  end
  
  defp create_system_prompt(data, persona) do
    # Build the system prompt from character data
    prompt_content = build_prompt_content(data)
    
    SystemPrompt.create(%{
      name: "#{data["name"]} - Imported Character",
      description: String.slice(data["description"] || "", 0, 200),
      content: prompt_content,
      persona_id: persona.id,
      is_active: true
    })
  end
  
  defp build_prompt_content(data) do
    # Use custom system prompt if provided (V2)
    parts = if data["system_prompt"] && data["system_prompt"] != "" do
      [data["system_prompt"]]
    else
      # Build from components
      [
        "You are #{data["name"]}.",
        data["description"],
        if(data["personality"], do: "\n\nPersonality:\n#{data["personality"]}", else: nil),
        if(data["scenario"], do: "\n\nScenario:\n#{data["scenario"]}", else: nil),
        if(data["creator_notes"], do: "\n\nNotes:\n#{data["creator_notes"]}", else: nil)
      ]
    end
    
    parts
    |> Enum.filter(& &1)
    |> Enum.join("\n\n")
    |> String.trim()
  end
  
  defp create_agent_card(data, system_prompt) do
    # Extract greeting for later use
    greeting = data["first_mes"] || "Hello!"
    
    # Handle alternate greetings if present (V2)
    greetings = case data["alternate_greetings"] do
      list when is_list(list) -> [greeting | list]
      _ -> [greeting]
    end
    
    # Extract tags
    tags = data["tags"] || []
    
    # Model preferences
    model_preferences = %{
      temperature: get_in(data, ["extensions", "temperature"]) || 0.8,
      top_p: get_in(data, ["extensions", "top_p"]) || 0.9,
      max_tokens: get_in(data, ["extensions", "max_tokens"]) || 500
    }
    
    AgentCard.create(%{
      name: data["name"],
      description: data["description"] || "Imported from SillyTavern",
      system_prompt_id: system_prompt.id,
      model_preferences: model_preferences,
      context_settings: %{
        greeting: greeting,
        alternate_greetings: greetings,
        example_messages: data["mes_example"],
        post_history_instructions: data["post_history_instructions"],
        tags: tags
      },
      is_default: false,
      add_to_new_rooms: false,
      available_tools: []
    })
  end
  
  @doc """
  Export an agent card to SillyTavern V2 JSON format.
  """
  def export_json(agent_card_id) when is_binary(agent_card_id) do
    with {:ok, agent_card} <- Ash.get(AgentCard, agent_card_id, load: [:system_prompt]) do
      export_agent_to_json(agent_card)
    end
  end
  
  defp export_agent_to_json(agent_card) do
    data = %{
      "name" => agent_card.name,
      "description" => agent_card.description,
      "personality" => "",  # Could extract from system prompt
      "scenario" => "",     # Could extract from system prompt
      "first_mes" => get_in(agent_card.context_settings, ["greeting"]) || "Hello!",
      "mes_example" => get_in(agent_card.context_settings, ["example_messages"]) || "",
      "creator_notes" => "Exported from AshChat",
      "system_prompt" => agent_card.system_prompt.content,
      "post_history_instructions" => get_in(agent_card.context_settings, ["post_history_instructions"]) || "",
      "alternate_greetings" => get_in(agent_card.context_settings, ["alternate_greetings"]) || [],
      "tags" => get_in(agent_card.context_settings, ["tags"]) || [],
      "creator" => "AshChat",
      "character_version" => "1.0",
      "extensions" => %{
        "temperature" => agent_card.model_preferences["temperature"] || 0.8,
        "top_p" => agent_card.model_preferences["top_p"] || 0.9,
        "max_tokens" => agent_card.model_preferences["max_tokens"] || 500
      }
    }
    
    v2_card = %{
      "spec" => "chara_card_v2",
      "spec_version" => "2.0",
      "data" => data
    }
    
    case Jason.encode(v2_card, pretty: true) do
      {:ok, json} -> {:ok, json}
      {:error, reason} -> {:error, "Failed to encode JSON: #{inspect(reason)}"}
    end
  end
end