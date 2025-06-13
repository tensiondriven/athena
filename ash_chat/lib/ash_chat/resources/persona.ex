defmodule AshChat.Resources.Persona do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "AI persona with provider settings and context assembly rules"
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :persona_type, :string, public?: true # "Role", "Character"
    attribute :provider, :string, public?: true # "ollama", "openai", "anthropic", "claude_oneshot"
    attribute :url, :string, public?: true
    attribute :api_key, :string, public?: true, sensitive?: true
    attribute :model, :string, public?: true # Current model or blank if none loaded
    attribute :is_default, :boolean, default: false, public?: true
    
    # Context Assembly Configuration
    attribute :context_settings, :map, public?: true, default: %{}
    attribute :system_prompt, :string, public?: true
    attribute :conversation_style, :map, public?: true, default: %{}
    
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  validations do
    validate present(:name), message: "Persona name is required"
    validate present(:persona_type), message: "Persona type is required"
    validate one_of(:persona_type, ["Role", "Character"]),
      message: "Persona type must be Role or Character"
    validate present(:provider), message: "Provider is required"
    validate one_of(:provider, ["ollama", "openrouter", "anthropic", "claude_oneshot"]), 
      message: "Provider must be ollama, openrouter, anthropic, or claude_oneshot"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :persona_type, :provider, :url, :api_key, :model, :is_default, :context_settings, :system_prompt, :conversation_style]
      
      change fn changeset, _context ->
        # If this is being set as default, unset other defaults
        if Ash.Changeset.get_attribute(changeset, :is_default) do
          # Clear other defaults (this would need to be implemented properly)
          changeset
        else
          changeset
        end
      end
    end
    
    read :get do
      get? true
    end

    read :default do
      filter expr(is_default == true)
    end

    update :set_as_default do
      accept []
      change set_attribute(:is_default, true)
      # TODO: Clear other defaults in a proper change
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :get
    define :update
    define :destroy
    define :get_default, action: :default
    define :set_as_default
  end
end