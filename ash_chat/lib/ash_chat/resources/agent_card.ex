defmodule AshChat.Resources.AgentCard do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Character profiles for AI agents with system messages and preferences"
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :description, :string, public?: true # Brief description of the character
    attribute :system_message, :string, public?: true # Core personality prompt
    attribute :model_preferences, :map, public?: true, default: %{} # temperature, top_p, etc.
    attribute :available_tools, {:array, :string}, public?: true, default: [] # tool names this agent can use
    attribute :context_settings, :map, public?: true, default: %{} # history_limit, vector_search, etc.
    attribute :avatar_url, :string, public?: true # Optional character avatar
    attribute :is_default, :boolean, default: false, public?: true
    attribute :add_to_new_rooms, :boolean, default: false, public?: true # Auto-join new rooms
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :default_profile, AshChat.Resources.Profile do
      source_attribute :default_profile_id
      destination_attribute :id
    end
    
    has_many :agent_memberships, AshChat.Resources.AgentMembership do
      destination_attribute :agent_card_id
    end
    
    many_to_many :rooms, AshChat.Resources.Room do
      through AshChat.Resources.AgentMembership
      source_attribute_on_join_resource :agent_card_id
      destination_attribute_on_join_resource :room_id
    end
  end

  validations do
    validate present(:name), message: "Agent name is required"
    validate present(:system_message), message: "System message is required"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :description, :system_message, :model_preferences, 
              :available_tools, :context_settings, :avatar_url, :is_default, :add_to_new_rooms, :default_profile_id]
      
      change fn changeset, _context ->
        # If this is being set as default, unset other defaults
        if Ash.Changeset.get_attribute(changeset, :is_default) do
          # TODO: Clear other defaults in a proper change
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

    read :auto_join_new_rooms do
      filter expr(add_to_new_rooms == true)
    end

    update :set_as_default do
      accept []
      change set_attribute(:is_default, true)
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
    define :get_auto_join_agents, action: :auto_join_new_rooms
    define :set_as_default
  end
end