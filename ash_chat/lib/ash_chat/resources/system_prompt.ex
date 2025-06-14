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

    attribute :version, :string do
      public? true
      description "Version identifier for this prompt (e.g., '1.0', '1.1', '2.0-beta')"
    end

    attribute :version_notes, :string do
      public? true
      description "Notes about what changed in this version"
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

    # Track the original prompt this was derived from
    belongs_to :parent_prompt, __MODULE__ do
      public? true
      description "The original prompt this version was derived from"
    end

    # Track all versions derived from this prompt
    has_many :versions, __MODULE__ do
      public? true
      destination_attribute :parent_prompt_id
      description "All versions derived from this prompt"
    end
  end

  validations do
    validate present(:name), message: "System prompt name is required"
    validate present(:content), message: "System prompt content is required"
    validate present(:persona_id), message: "Persona (backend) is required"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :content, :description, :persona_id, :is_active, :version, :version_notes, :parent_prompt_id]
    end
    
    update :update do
      accept [:name, :content, :description, :persona_id, :is_active, :version, :version_notes]
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