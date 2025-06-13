defmodule AshChat.Resources.SystemPrompt do
  @moduledoc """
  SystemPrompt defines reusable system prompts that can be assigned to agents.
  
  Simpler than PromptTemplate - just focuses on system prompt content and
  which backend (Profile) it should use.
  """
  
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Reusable system prompts for AI agents"
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
      description "Display name for this system prompt"
    end

    attribute :content, :string do
      allow_nil? false
      public? true
      description "The actual system prompt content"
    end

    attribute :description, :string do
      public? true
      description "Optional description of what this prompt does"
    end

    attribute :is_active, :boolean do
      default true
      public? true
      description "Whether this prompt is available for use"
    end

    timestamps()
  end

  relationships do
    belongs_to :persona, AshChat.Resources.Persona do
      public? true
      allow_nil? false
      description "Which backend persona (provider) to use with this prompt"
    end

    has_many :agent_cards, AshChat.Resources.AgentCard do
      public? true
      description "Agent cards using this system prompt"
    end
  end

  validations do
    validate present(:name), message: "System prompt name is required"
    validate present(:content), message: "System prompt content is required"
    validate present(:profile_id), message: "Profile (backend) is required"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :content, :description, :persona_id, :is_active]
    end
    
    update :update do
      accept [:name, :content, :description, :persona_id, :is_active]
    end
    
    read :active do
      filter expr(is_active == true)
    end

    read :by_persona do
      argument :persona_id, :uuid, allow_nil?: false
      filter expr(persona_id == ^arg(:persona_id) and is_active == true)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :update
    define :destroy
    define :active
    define :by_persona, args: [:persona_id]
  end
end