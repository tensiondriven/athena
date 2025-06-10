defmodule AshChat.Resources.RoomMembership do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "Join table for many-to-many relationship between users and rooms"
  end

  attributes do
    uuid_primary_key :id
    attribute :role, :string, public?: true, default: "member" # "member", "moderator", "admin"
    attribute :joined_at, :utc_datetime_usec, default: &DateTime.utc_now/0, public?: true
    attribute :last_seen_at, :utc_datetime_usec, public?: true
    attribute :is_active, :boolean, default: true, public?: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, AshChat.Resources.User do
      source_attribute :user_id
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
    validate present(:user_id), message: "User is required"
    validate present(:room_id), message: "Room is required"
    validate one_of(:role, ["member", "moderator", "admin"]), message: "Role must be member, moderator, or admin"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:user_id, :room_id, :role]
      
      change fn changeset, _context ->
        # Set joined_at and last_seen_at to now if not provided
        now = DateTime.utc_now()
        changeset
        |> Ash.Changeset.change_attribute(:joined_at, now)
        |> Ash.Changeset.change_attribute(:last_seen_at, now)
      end
    end
    
    read :get do
      get? true
    end

    read :for_user do
      argument :user_id, :uuid, allow_nil?: false
      filter expr(user_id == ^arg(:user_id) and is_active == true)
    end

    read :for_room do
      argument :room_id, :uuid, allow_nil?: false
      filter expr(room_id == ^arg(:room_id) and is_active == true)
    end

    read :for_user_and_room do
      argument :user_id, :uuid, allow_nil?: false
      argument :room_id, :uuid, allow_nil?: false
      filter expr(user_id == ^arg(:user_id) and room_id == ^arg(:room_id) and is_active == true)
    end

    update :update_last_seen do
      accept []
      change set_attribute(:last_seen_at, &DateTime.utc_now/0)
    end

    update :promote_to_moderator do
      accept []
      change set_attribute(:role, "moderator")
    end

    update :promote_to_admin do
      accept []
      change set_attribute(:role, "admin")
    end

    update :demote_to_member do
      accept []
      change set_attribute(:role, "member")
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
    define :for_user
    define :for_room
    define :for_user_and_room
    define :update_last_seen
    define :promote_to_moderator
    define :promote_to_admin
    define :demote_to_member
    define :leave_room
  end
end