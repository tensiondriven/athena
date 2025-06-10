defmodule AshChat.Resources.Profile do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "AI provider profile with connection settings"
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :provider, :string, public?: true # "ollama", "openai", "anthropic"
    attribute :url, :string, public?: true
    attribute :api_key, :string, public?: true, sensitive?: true
    attribute :model, :string, public?: true # Current model or blank if none loaded
    attribute :is_default, :boolean, default: false, public?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  validations do
    validate present(:name), message: "Profile name is required"
    validate present(:provider), message: "Provider is required"
    validate one_of(:provider, ["ollama", "openai", "anthropic"]), 
      message: "Provider must be ollama, openai, or anthropic"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :provider, :url, :api_key, :model, :is_default]
      
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