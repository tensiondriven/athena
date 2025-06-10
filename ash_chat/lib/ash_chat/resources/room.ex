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
    attribute :profile_id, :uuid
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :messages, AshChat.Resources.Message do
      destination_attribute :room_id
    end
    
    belongs_to :profile, AshChat.Resources.Profile do
      source_attribute :profile_id
      destination_attribute :id
    end
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:title, :profile_id]
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