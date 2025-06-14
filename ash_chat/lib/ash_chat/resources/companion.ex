defmodule AshChat.Resources.Companion do
  @moduledoc """
  Unified Companion entity for all chat participants - AI assistants, simulated people,
  experts, friends, etc. Combines identity, backend config, and personality.
  This replaces the previous Persona, SystemPrompt, and AgentCard resources.
  """
  
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Chat companion with complete configuration"
  end

  attributes do
    uuid_primary_key :id
    
    # Identity
    attribute :name, :string, public?: true
    attribute :description, :string, public?: true
    attribute :avatar_url, :string, public?: true
    
    # Companion Type
    attribute :companion_type, :atom do
      public? true
      constraints one_of: [:assistant, :employee, :visitor, :guest, :expert, :friend, :character]
      default :assistant
    end
    
    # Backend Configuration
    attribute :provider, :atom do
      public? true
      constraints one_of: [:ollama, :openrouter, :claude_oneshot, :claude_session]
    end
    attribute :endpoint, :string, public?: true
    attribute :api_key, :string, public?: true, sensitive?: true
    attribute :model, :string, public?: true
    
    # Personality
    attribute :system_prompt, :string, public?: true
    
    # Inference Settings
    attribute :temperature, :float, public?: true, default: 0.7
    attribute :max_tokens, :integer, public?: true, default: 500
    attribute :top_p, :float, public?: true, default: 0.9
    attribute :top_k, :integer, public?: true
    
    # Context Strategy
    attribute :context_format, :atom do
      public? true
      default :consolidated
      constraints one_of: [:consolidated, :message_per_message, :claude_style]
    end
    attribute :context_window, :integer, public?: true, default: 20
    
    # Features & Capabilities
    attribute :available_tools, {:array, :string}, public?: true, default: []
    attribute :capabilities, {:array, :atom}, public?: true, default: []
    # e.g. [:memory, :web_search, :code_execution, :image_generation]
    
    # Social Metadata
    attribute :tags, {:array, :string}, public?: true, default: []
    # e.g. ["technical", "friendly", "professional", "creative"]
    attribute :personality_notes, :string, public?: true
    # Free-form notes about personality traits, backstory, etc.
    
    # Behavior Settings
    attribute :add_to_new_rooms, :boolean, public?: true, default: false
    attribute :is_default, :boolean, public?: true, default: false
    attribute :is_active, :boolean, public?: true, default: true
    attribute :auto_respond, :boolean, public?: true, default: true
    attribute :response_style, :map, public?: true, default: %{}
    # e.g. %{formality: "casual", verbosity: "concise", emoji_use: true}
    
    # Versioning
    attribute :version, :integer, public?: true, default: 1
    attribute :parent_companion_id, :uuid, public?: true
    attribute :version_notes, :string, public?: true
    
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  validations do
    validate present(:name), message: "Companion name is required"
    validate present(:provider), message: "Provider is required"
    validate present(:model), message: "Model is required"
    validate present(:system_prompt), message: "System prompt is required"
    
    # Provider-specific validations
    validate present(:endpoint), 
      where: [attribute_in(:provider, [:ollama, :openrouter])],
      message: "Endpoint URL is required for this provider"
      
    validate present(:api_key),
      where: [attribute_equals(:provider, :openrouter)],
      message: "API key is required for OpenRouter"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [
        :name, :description, :avatar_url,
        :provider, :endpoint, :api_key, :model,
        :system_prompt,
        :temperature, :max_tokens, :top_p, :top_k,
        :context_format, :context_window,
        :available_tools, :capabilities, :tags, :personality_notes,
        :add_to_new_rooms, :is_default, :is_active, :auto_respond,
        :response_style,
        :version, :parent_companion_id, :version_notes, :companion_type
      ]
      
      change fn changeset, _context ->
        # If setting as default, unset other defaults
        if Ash.Changeset.get_attribute(changeset, :is_default) do
          # TODO: Implement unsetting other defaults
          changeset
        else
          changeset
        end
      end
    end
    
    update :update do
      accept [
        :name, :description, :avatar_url,
        :endpoint, :api_key, :model,
        :system_prompt,
        :temperature, :max_tokens, :top_p, :top_k,
        :context_format, :context_window,
        :available_tools, :capabilities, :tags, :personality_notes,
        :add_to_new_rooms, :is_default, :is_active, :auto_respond,
        :response_style
      ]
    end
    
    update :duplicate do
      manual fn changeset, _context ->
        original = changeset.data
        
        new_attrs = %{
          name: "#{original.name} (Copy)",
          description: original.description,
          avatar_url: original.avatar_url,
          provider: original.provider,
          endpoint: original.endpoint,
          api_key: original.api_key,
          model: original.model,
          system_prompt: original.system_prompt,
          temperature: original.temperature,
          max_tokens: original.max_tokens,
          top_p: original.top_p,
          top_k: original.top_k,
          context_format: original.context_format,
          context_window: original.context_window,
          available_tools: original.available_tools,
          capabilities: original.capabilities,
          tags: original.tags,
          personality_notes: original.personality_notes,
          response_style: original.response_style,
          auto_respond: original.auto_respond,
          add_to_new_rooms: false,
          is_default: false,
          is_active: true,
          version: 1,
          parent_companion_id: original.id,
          companion_type: original.companion_type,
          version_notes: "Duplicated from #{original.name}"
        }
        
        case __MODULE__.create(new_attrs) do
          {:ok, new_companion} -> {:ok, new_companion}
          {:error, error} -> {:error, error}
        end
      end
    end
    
    read :get do
      get? true
    end
    
    read :active do
      filter expr(is_active == true)
    end
    
    read :default do
      filter expr(is_default == true)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :get
    define :update
    define :destroy
    define :duplicate
    define :get_active, action: :active
    define :get_default, action: :default
  end
end