defmodule AshChat.Resources.Room do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A chat room/channel for conversations"
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, default: "New Room"
    attribute :hidden, :boolean, default: false
    attribute :parent_room_id, :uuid
    attribute :agent_card_id, :uuid
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :messages, AshChat.Resources.Message do
      destination_attribute :room_id
    end
    
    has_many :room_memberships, AshChat.Resources.RoomMembership do
      destination_attribute :room_id
    end
    
    many_to_many :users, AshChat.Resources.User do
      through AshChat.Resources.RoomMembership
      source_attribute_on_join_resource :room_id
      destination_attribute_on_join_resource :user_id
    end
    
    belongs_to :parent_room, AshChat.Resources.Room do
      source_attribute :parent_room_id
      destination_attribute :id
    end
    
    has_many :child_rooms, AshChat.Resources.Room do
      destination_attribute :parent_room_id
    end
    
    belongs_to :agent_card, AshChat.Resources.AgentCard do
      source_attribute :agent_card_id
      destination_attribute :id
    end
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:title, :parent_room_id, :agent_card_id]
      change set_attribute(:title, "New Multimodal Room")
    end
    
    read :get do
      get? true
    end

    read :visible do
      filter expr(hidden == false)
    end

    read :all do
      # No filter, returns all rooms including hidden
    end

    update :hide do
      accept []
      change set_attribute(:hidden, true)
    end

    update :unhide do
      accept []
      change set_attribute(:hidden, false)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :get
    define :list_visible, action: :visible
    define :list_all, action: :all
    define :update
    define :hide
    define :unhide
  end
end