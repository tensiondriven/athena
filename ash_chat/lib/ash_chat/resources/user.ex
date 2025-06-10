defmodule AshChat.Resources.User do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A human user who can participate in chat rooms"
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :email, :string, public?: true
    attribute :display_name, :string, public?: true # How they appear in chat
    attribute :avatar_url, :string, public?: true
    attribute :preferences, :map, public?: true, default: %{} # User preferences, themes, etc.
    attribute :is_active, :boolean, default: true, public?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :messages, AshChat.Resources.Message do
      destination_attribute :user_id
    end
    
    has_many :room_memberships, AshChat.Resources.RoomMembership do
      destination_attribute :user_id
    end
    
    many_to_many :rooms, AshChat.Resources.Room do
      through AshChat.Resources.RoomMembership
      source_attribute_on_join_resource :user_id
      destination_attribute_on_join_resource :room_id
    end
  end

  validations do
    validate present(:name), message: "User name is required"
    validate present(:display_name), message: "Display name is required"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :email, :display_name, :avatar_url, :preferences, :is_active]
      
      change fn changeset, _context ->
        # Set display_name to name if not provided
        case Ash.Changeset.get_attribute(changeset, :display_name) do
          nil -> 
            name = Ash.Changeset.get_attribute(changeset, :name)
            Ash.Changeset.change_attribute(changeset, :display_name, name)
          _ -> 
            changeset
        end
      end
    end
    
    read :get do
      get? true
    end

    read :active do
      filter expr(is_active == true)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :get
    define :update
    define :destroy
    define :list_active, action: :active
  end
end