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
    attribute :description, :string do
      description "Optional room description explaining its purpose"
    end
    attribute :current_task, :string do
      description "Current active task or objective for this room"
    end
    attribute :hidden, :boolean, default: false
    attribute :parent_room_id, :uuid
    attribute :starting_message, :string do
      description "Optional context or introductory message that appears at the beginning of the room"
    end
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
    
    has_many :agent_memberships, AshChat.Resources.AgentMembership do
      destination_attribute :room_id
    end
    
    many_to_many :agent_cards, AshChat.Resources.AgentCard do
      through AshChat.Resources.AgentMembership
      source_attribute_on_join_resource :room_id
      destination_attribute_on_join_resource :agent_card_id
    end
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:title, :description, :current_task, :parent_room_id, :starting_message, :hidden]
      
      # Add persistence hook
      change fn changeset, _context ->
        changeset
        |> Ash.Changeset.after_action(fn _changeset, result ->
          Task.start(fn ->
            persist_to_sqlite(result)
          end)
          {:ok, result}
        end)
      end
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
    define :destroy
    define :hide
    define :unhide
  end
  
  # Simple SQLite persistence
  defp persist_to_sqlite(room) do
    case Exqlite.Sqlite3.open("ash_chat.db") do
      {:ok, conn} ->
        # Create table if not exists
        Exqlite.Sqlite3.execute(conn, """
        CREATE TABLE IF NOT EXISTS rooms (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          parent_room_id TEXT,
          starting_message TEXT,
          hidden INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
        """)
        
        # Insert room
        {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
        INSERT OR REPLACE INTO rooms (id, title, parent_room_id, starting_message, hidden, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """)
        
        :ok = Exqlite.Sqlite3.bind(statement, [
          room.id,
          room.title,
          room.parent_room_id || "",
          room.starting_message || "",
          if(room.hidden, do: 1, else: 0),
          DateTime.to_iso8601(room.created_at)
        ])
        
        Exqlite.Sqlite3.step(conn, statement)
        Exqlite.Sqlite3.release(conn, statement)
        Exqlite.Sqlite3.close(conn)
      _ ->
        :ok  # Fail silently - don't break chat if DB is down
    end
  end
end