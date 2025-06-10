defmodule AshChat.DemoData do
  @moduledoc """
  Creates demo data for Characters and PromptTemplates to showcase the system.
  """
  
  alias AshChat.Resources.{Character, PromptTemplate, User, Room, RoomMembership}
  
  def seed_all do
    seed_prompt_templates()
    seed_characters()
    seed_jonathan_setup()
  end
  
  def seed_prompt_templates do
    templates = [
      # ChatML Template (for Qwen, ChatGLM, etc.)
      %{
        name: "ChatML",
        model_family: "qwen",
        description: "ChatML format used by Qwen and similar models",
        system_template: "<|im_start|>system\n{{content}}<|im_end|>\n",
        user_template: "<|im_start|>user\n{{content}}<|im_end|>\n",
        assistant_template: "<|im_start|>assistant\n{{content}}<|im_end|>\n",
        conversation_starter: "",
        conversation_ender: "<|im_start|>assistant\n",
        special_tokens: %{
          "bos" => "<|im_start|>",
          "eos" => "<|im_end|>"
        },
        stop_sequences: ["<|im_end|>"],
        requires_system_message: true,
        supports_multi_turn: true,
        max_context_tokens: 8192,
        is_active: true,
        is_default_for_family: true
      },
      
      # Alpaca Template
      %{
        name: "Alpaca",
        model_family: "llama",
        description: "Alpaca instruction format for Llama-based models",
        system_template: "{{content}}\n\n",
        user_template: "### Instruction:\n{{content}}\n\n",
        assistant_template: "### Response:\n{{content}}\n\n",
        conversation_starter: "",
        conversation_ender: "### Response:\n",
        special_tokens: %{},
        stop_sequences: ["###"],
        requires_system_message: false,
        supports_multi_turn: true,
        max_context_tokens: 4096,
        is_active: true,
        is_default_for_family: false
      },
      
      # Llama 3 Template
      %{
        name: "Llama 3",
        model_family: "llama3",
        description: "Official Llama 3 chat template",
        system_template: "<|start_header_id|>system<|end_header_id|>\n\n{{content}}<|eot_id|>",
        user_template: "<|start_header_id|>user<|end_header_id|>\n\n{{content}}<|eot_id|>",
        assistant_template: "<|start_header_id|>assistant<|end_header_id|>\n\n{{content}}<|eot_id|>",
        conversation_starter: "<|begin_of_text|>",
        conversation_ender: "<|start_header_id|>assistant<|end_header_id|>\n\n",
        special_tokens: %{
          "bos" => "<|begin_of_text|>",
          "eos" => "<|eot_id|>"
        },
        stop_sequences: ["<|eot_id|>"],
        requires_system_message: true,
        supports_multi_turn: true,
        max_context_tokens: 8192,
        is_active: true,
        is_default_for_family: true
      },
      
      # Mistral Template
      %{
        name: "Mistral",
        model_family: "mistral", 
        description: "Mistral instruction format",
        system_template: "{{content}}\n\n",
        user_template: "[INST] {{content}} [/INST]",
        assistant_template: "{{content}}</s>",
        conversation_starter: "<s>",
        conversation_ender: "",
        special_tokens: %{
          "bos" => "<s>",
          "eos" => "</s>"
        },
        stop_sequences: ["</s>"],
        requires_system_message: false,
        supports_multi_turn: true,
        max_context_tokens: 8192,
        is_active: true,
        is_default_for_family: true
      }
    ]
    
    Enum.each(templates, fn template_data ->
      case PromptTemplate.create(template_data) do
        {:ok, template} -> 
          IO.puts("Created template: #{template.name}")
        {:error, error} -> 
          IO.puts("Failed to create template #{template_data.name}: #{inspect(error)}")
      end
    end)
  end
  
  def seed_characters do
    characters = [
      # Helpful Alice
      %{
        sillytavern_data: %{
          "name" => "Helpful Alice",
          "description" => "A supportive AI assistant focused on helping users succeed",
          "personality" => "Empathetic, encouraging, patient, and always looking for ways to help others feel supported and capable",
          "first_mes" => "Hello! I'm Alice, and I'm here to help you succeed. What can I assist you with today?",
          "scenario" => "You are interacting with Alice, a helpful AI assistant who specializes in providing support and guidance",
          "char_persona" => "Helpful Alice is an empathetic AI who believes everyone can succeed with the right support",
          "world_scenario" => "A supportive environment where learning and growth are encouraged",
          "char_greeting" => "Hello! I'm Alice, and I'm here to help you succeed. What can I assist you with today?",
          "example_dialogue" => "{{user}}: I'm struggling with this problem.\n{{char}}: I understand that can be frustrating. Let's break it down together step by step. What specific part is giving you trouble?",
          "tags" => ["helpful", "supportive", "teaching"]
        },
        name: "Helpful Alice",
        description: "A supportive AI assistant focused on helping users succeed",
        personality: "Empathetic, encouraging, patient, and always looking for ways to help others feel supported and capable",
        first_message: "Hello! I'm Alice, and I'm here to help you succeed. What can I assist you with today?",
        scenario: "You are interacting with Alice, a helpful AI assistant who specializes in providing support and guidance",
        tags: ["helpful", "supportive", "teaching"],
        is_active: true
      },
      
      # Direct Dave
      %{
        sillytavern_data: %{
          "name" => "Direct Dave",
          "description" => "A straightforward code reviewer who provides honest, direct feedback",
          "personality" => "Analytical, direct, no-nonsense, focused on code quality and best practices",
          "first_mes" => "I'm Dave. Show me your code and I'll tell you what's wrong with it and how to fix it.",
          "scenario" => "You are working with Dave, a senior developer who reviews code with brutal honesty but always aims to improve quality",
          "char_persona" => "Direct Dave is a senior developer who believes in honest feedback and high standards",
          "world_scenario" => "A professional development environment where code quality is paramount",
          "char_greeting" => "I'm Dave. Show me your code and I'll tell you what's wrong with it and how to fix it.",
          "example_dialogue" => "{{user}}: What do you think of this function?\n{{char}}: It works, but it's inefficient and hard to read. Here's what you need to change...",
          "tags" => ["code-review", "direct", "technical"]
        },
        name: "Direct Dave",
        description: "A straightforward code reviewer who provides honest, direct feedback", 
        personality: "Analytical, direct, no-nonsense, focused on code quality and best practices",
        first_message: "I'm Dave. Show me your code and I'll tell you what's wrong with it and how to fix it.",
        scenario: "You are working with Dave, a senior developer who reviews code with brutal honesty but always aims to improve quality",
        tags: ["code-review", "direct", "technical"],
        is_active: true
      },
      
      # Creative Casey
      %{
        sillytavern_data: %{
          "name" => "Creative Casey",
          "description" => "An energetic brainstorming facilitator who loves generating novel ideas",
          "personality" => "Energetic, creative, enthusiastic, loves thinking outside the box and inspiring innovation",
          "first_mes" => "Hey there! I'm Casey and I LOVE brainstorming! What wild ideas are we cooking up today?",
          "scenario" => "You are brainstorming with Casey, a creative facilitator who excels at generating innovative solutions",
          "char_persona" => "Creative Casey thrives on innovation and believes there's always a creative solution",
          "world_scenario" => "A creative workshop environment where all ideas are welcome and innovation is encouraged",
          "char_greeting" => "Hey there! I'm Casey and I LOVE brainstorming! What wild ideas are we cooking up today?",
          "example_dialogue" => "{{user}}: We need a new approach to this problem.\n{{char}}: Ooh, I love challenges! What if we completely flip our assumptions? What if instead of solving it directly, we...",
          "tags" => ["creative", "brainstorming", "innovation"]
        },
        name: "Creative Casey",
        description: "An energetic brainstorming facilitator who loves generating novel ideas",
        personality: "Energetic, creative, enthusiastic, loves thinking outside the box and inspiring innovation",
        first_message: "Hey there! I'm Casey and I LOVE brainstorming! What wild ideas are we cooking up today?",
        scenario: "You are brainstorming with Casey, a creative facilitator who excels at generating innovative solutions",
        tags: ["creative", "brainstorming", "innovation"],
        is_active: true
      },
      
      # Wise Professor
      %{
        sillytavern_data: %{
          "name" => "Professor Williams",
          "description" => "A patient educator who excels at explaining complex technical concepts clearly",
          "personality" => "Patient, thorough, wise, enjoys teaching and sharing deep knowledge in an accessible way",
          "first_mes" => "Good day! I'm Professor Williams. What would you like to learn about today? I'll make sure you understand it thoroughly.",
          "scenario" => "You are learning from Professor Williams, an experienced educator who can explain any technical concept clearly",
          "char_persona" => "Professor Williams is a patient educator who believes understanding comes from clear explanations and good examples",
          "world_scenario" => "An academic environment focused on deep learning and understanding",
          "char_greeting" => "Good day! I'm Professor Williams. What would you like to learn about today? I'll make sure you understand it thoroughly.",
          "example_dialogue" => "{{user}}: I don't understand how this algorithm works.\n{{char}}: Excellent question! Let's start with the fundamental principles. Think of it like this...",
          "tags" => ["education", "patient", "thorough"]
        },
        name: "Professor Williams",
        description: "A patient educator who excels at explaining complex technical concepts clearly",
        personality: "Patient, thorough, wise, enjoys teaching and sharing deep knowledge in an accessible way",
        first_message: "Good day! I'm Professor Williams. What would you like to learn about today? I'll make sure you understand it thoroughly.",
        scenario: "You are learning from Professor Williams, an experienced educator who can explain any technical concept clearly",
        tags: ["education", "patient", "thorough"],
        is_active: true
      }
    ]
    
    Enum.each(characters, fn character_data ->
      case Character.create(character_data) do
        {:ok, character} -> 
          IO.puts("Created character: #{character.name}")
        {:error, error} -> 
          IO.puts("Failed to create character #{character_data.name}: #{inspect(error)}")
      end
    end)
  end
  
  def seed_jonathan_setup do
    # Load configuration from YAML
    config_path = Path.join([Application.app_dir(:ash_chat), "priv", "config", "jonathan_setup.yaml"])
    config = case YamlElixir.read_from_file(config_path) do
      {:ok, data} -> data
      {:error, _} -> 
        # Fallback to local config path if priv doesn't exist
        local_path = Path.join(["config", "jonathan_setup.yaml"])
        case YamlElixir.read_from_file(local_path) do
          {:ok, data} -> data
          {:error, error} -> 
            IO.puts("Failed to load YAML config: #{inspect(error)}")
            raise "Could not load jonathan_setup.yaml"
        end
    end
    
    # Find or create Jonathan as a User (idempotent)
    user_config = config["user"]
    jonathan_user = case User.read!() |> Enum.find(&(&1.email == user_config["email"])) do
      nil ->
        jonathan_user_data = %{
          name: user_config["name"],
          display_name: user_config["display_name"],
          email: user_config["email"],
          preferences: user_config["preferences"],
          is_active: user_config["is_active"]
        }
        
        case User.create(jonathan_user_data) do
          {:ok, user} -> 
            IO.puts("Created user: #{user.display_name}")
            user
          {:error, error} -> 
            IO.puts("Failed to create user #{user_config["name"]}: #{inspect(error)}")
            nil
        end
      
      existing_user ->
        IO.puts("Found existing user: #{existing_user.display_name}")
        existing_user
    end
    
    # Create characters from config (idempotent)
    _characters = Enum.map(config["characters"], fn char_config ->
      case Character.read!() |> Enum.find(&(&1.name == char_config["name"])) do
        nil ->
          character_data = %{
            sillytavern_data: char_config["sillytavern_data"],
            name: char_config["name"],
            description: char_config["description"],
            personality: char_config["personality"],
            first_message: char_config["first_message"],
            scenario: char_config["scenario"],
            tags: char_config["tags"],
            is_active: char_config["is_active"]
          }
          
          case Character.create(character_data) do
            {:ok, character} -> 
              IO.puts("Created character: #{character.name}")
              character
            {:error, error} -> 
              IO.puts("Failed to create character #{char_config["name"]}: #{inspect(error)}")
              nil
          end
        
        existing_character ->
          IO.puts("Found existing character: #{existing_character.name}")
          existing_character
      end
    end)
    
    # Optionally create room if configured (idempotent)
    case config["room"] do
      nil ->
        IO.puts("No room configured - rooms will be created explicitly by user")
      
      room_config ->
        room = case Room.read!() |> Enum.find(&(&1.title == room_config["title"])) do
          nil ->
            room_data = %{
              title: room_config["title"],
              starting_message: room_config["starting_message"],
              hidden: room_config["hidden"]
            }
            
            case Room.create(room_data) do
              {:ok, room} -> 
                IO.puts("Created room: #{room.title}")
                room
              {:error, error} -> 
                IO.puts("Failed to create room: #{inspect(error)}")
                nil
            end
          
          existing_room ->
            IO.puts("Found existing room: #{existing_room.title}")
            existing_room
        end
        
        # Add user to the room if not already a member
        if jonathan_user && room && config["membership"] do
          existing_membership = RoomMembership.read!() 
            |> Enum.find(&(&1.user_id == jonathan_user.id && &1.room_id == room.id && &1.is_active))
          
          case existing_membership do
            nil ->
              membership_config = config["membership"]
              case RoomMembership.create(%{user_id: jonathan_user.id, room_id: room.id, role: membership_config["role"]}) do
                {:ok, _membership} -> 
                  IO.puts("Added #{user_config["name"]} to the room as #{membership_config["role"]}")
                {:error, error} -> 
                  IO.puts("Failed to add #{user_config["name"]} to room: #{inspect(error)}")
              end
            
            _existing ->
              IO.puts("#{user_config["name"]} is already a member of the room")
          end
        end
    end
    
    IO.puts("Setup complete! User created, characters defined, and collaborative room established.")
  end
  
  def clear_all do
    # Clear existing demo data (useful for development)
    RoomMembership.read!() |> Enum.each(&RoomMembership.destroy/1)
    Room.read!() |> Enum.each(&Room.destroy/1)
    User.read!() |> Enum.each(&User.destroy/1)
    PromptTemplate.read!() |> Enum.each(&PromptTemplate.destroy/1)
    Character.read!() |> Enum.each(&Character.destroy/1)
    IO.puts("Cleared all demo data")
  end
end