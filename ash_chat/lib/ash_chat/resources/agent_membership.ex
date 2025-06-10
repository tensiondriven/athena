defmodule AshChat.Resources.AgentMembership do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Join table for many-to-many relationship between agents and rooms"
  end

  attributes do
    uuid_primary_key :id
    attribute :role, :string, public?: true, default: "participant" # "participant", "moderator"
    attribute :joined_at, :utc_datetime_usec, default: &DateTime.utc_now/0, public?: true
    attribute :is_active, :boolean, default: true, public?: true
    attribute :auto_respond, :boolean, default: true, public?: true # Whether this agent responds automatically
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :agent_card, AshChat.Resources.AgentCard do
      source_attribute :agent_card_id
      destination_attribute :id
      allow_nil? false
    end
    
    belongs_to :room, AshChat.Resources.Room do
      source_attribute :room_id
      destination_attribute :id
      allow_nil? false
    end
  end

  validations do
    validate present(:agent_card_id), message: "Agent is required"
    validate present(:room_id), message: "Room is required"
    validate one_of(:role, ["participant", "moderator"]), message: "Role must be participant or moderator"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:agent_card_id, :room_id, :role, :auto_respond]
      
      change fn changeset, _context ->
        # Set joined_at to now if not provided
        now = DateTime.utc_now()
        Ash.Changeset.change_attribute(changeset, :joined_at, now)
      end
    end
    
    read :get do
      get? true
    end

    read :for_agent do
      argument :agent_card_id, :uuid, allow_nil?: false
      filter expr(agent_card_id == ^arg(:agent_card_id) and is_active == true)
    end

    read :for_room do
      argument :room_id, :uuid, allow_nil?: false
      filter expr(room_id == ^arg(:room_id) and is_active == true)
    end

    read :for_agent_and_room do
      argument :agent_card_id, :uuid, allow_nil?: false
      argument :room_id, :uuid, allow_nil?: false
      filter expr(agent_card_id == ^arg(:agent_card_id) and room_id == ^arg(:room_id) and is_active == true)
    end

    read :auto_responders_for_room do
      argument :room_id, :uuid, allow_nil?: false
      filter expr(room_id == ^arg(:room_id) and is_active == true and auto_respond == true)
    end

    update :toggle_auto_respond do
      accept []
      change fn changeset, _context ->
        current_value = Ash.Changeset.get_attribute(changeset, :auto_respond)
        Ash.Changeset.change_attribute(changeset, :auto_respond, !current_value)
      end
    end

    update :leave_room do
      accept []
      change set_attribute(:is_active, false)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :get
    define :update
    define :destroy
    define :for_agent
    define :for_room
    define :for_agent_and_room
    define :auto_responders_for_room
    define :toggle_auto_respond
    define :leave_room
  end
end