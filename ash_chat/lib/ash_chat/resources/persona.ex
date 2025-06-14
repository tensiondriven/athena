defmodule AshChat.Resources.Persona do
  @moduledoc """
  Unified Persona entity for all chat participants - AI assistants, simulated people,
  experts, friends, etc. Combines identity, backend config, and personality.
  This consolidates the previous fragmented Persona, SystemPrompt, and AgentCard resources.
  """
  
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Chat persona with complete configuration"
  end

  attributes do
    uuid_primary_key :id
    
    # Identity
    attribute :name, :string, public?: true
    attribute :description, :string, public?: true
    attribute :avatar_url, :string, public?: true
    
    # Persona Type
    attribute :persona_type, :atom do
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
    
    # Persona Metadata
    attribute :version, :integer, public?: true, default: 1
    attribute :tags, {:array, :string}, public?: true, default: []
    attribute :capabilities, {:array, :atom}, public?: true, default: []
    attribute :available_tools, {:array, :string}, public?: true, default: []
    
    # Extended Personality
    attribute :personality_notes, :string, public?: true
    attribute :response_style, :map, public?: true
    # e.g., %{formality: :casual, verbosity: :moderate, emoji_use: true, humor: :occasional}
    
    # Behavior
    attribute :auto_respond, :boolean, public?: true, default: true
    attribute :is_default, :boolean, public?: true, default: false
    attribute :add_to_new_rooms, :boolean, public?: true, default: false
    
    timestamps()
  end

  actions do
    defaults [:read, :destroy]
    
    create :create do
      primary? true
      accept [:name, :description, :avatar_url, :persona_type, :provider, 
              :endpoint, :api_key, :model, :system_prompt, :temperature, 
              :max_tokens, :top_p, :top_k, :context_format, :context_window,
              :version, :tags, :capabilities, :available_tools, 
              :personality_notes, :response_style, :auto_respond, 
              :is_default, :add_to_new_rooms]
    end
    
    update :update do
      primary? true
      accept [:name, :description, :avatar_url, :persona_type, :provider, 
              :endpoint, :api_key, :model, :system_prompt, :temperature, 
              :max_tokens, :top_p, :top_k, :context_format, :context_window,
              :version, :tags, :capabilities, :available_tools, 
              :personality_notes, :response_style, :auto_respond, 
              :is_default, :add_to_new_rooms]
    end
    
    read :get_by_id do
      argument :id, :uuid do
        allow_nil? false
      end
      
      filter expr(id == ^arg(:id))
      get? true
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
    define :get_by_id, args: [:id], get?: true
  end

  # Persona Types:
  # - :assistant - AI helpers (Maya, ChatGPT-like)
  # - :expert - Domain specialists (Coda for coding)
  # - :employee - Simulated coworkers  
  # - :friend - Casual conversation partners
  # - :character - Fictional personas
  # - :visitor - Temporary participants
  # - :guest - External participants
end