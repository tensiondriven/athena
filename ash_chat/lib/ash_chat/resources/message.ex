defmodule AshChat.Resources.Message do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A message in a chat conversation"
  end

  # TODO: Add AshAI vectorization when vector store is configured
  # ash_ai do
  #   vectorize text: :content,
  #            on: [:create, :update],
  #            store: AshChat.VectorStore
  # end

  attributes do
    uuid_primary_key :id
    attribute :content, :string, allow_nil?: false
    attribute :role, :atom, constraints: [one_of: [:user, :assistant, :system]], default: :user
    attribute :message_type, :atom, constraints: [one_of: [:text, :image, :multimodal]], default: :text
    attribute :image_url, :string
    attribute :image_data, :binary
    attribute :metadata, :map, default: %{}
    attribute :user_id, :uuid  # Which user sent this message (for user messages)
    attribute :profile_id, :uuid  # Which profile generated this message (for assistant messages)
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :room, AshChat.Resources.Room
    belongs_to :user, AshChat.Resources.User do
      source_attribute :user_id
      destination_attribute :id
    end
    belongs_to :profile, AshChat.Resources.Profile do
      source_attribute :profile_id
      destination_attribute :id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
    
    create :create_and_persist do
      change fn changeset, _context ->
        # Simple SQLite persistence hook
        changeset
        |> Ash.Changeset.after_action(fn _changeset, result ->
          Task.start(fn ->
            persist_to_sqlite(result)
          end)
          {:ok, result}
        end)
      end
    end

    read :for_room do
      argument :room_id, :uuid, allow_nil?: false
      filter expr(room_id == ^arg(:room_id))
    end

    read :semantic_search do
      argument :query, :string, allow_nil?: false
      argument :limit, :integer, default: 10
      argument :threshold, :float, default: 0.8
      
      prepare fn query, _context ->
        # This will be handled by AshAI's semantic search
        query
      end
    end

    create :create_text_message do
      argument :room_id, :uuid, allow_nil?: false
      argument :content, :string, allow_nil?: false
      argument :role, :atom, default: :user
      argument :user_id, :uuid
      argument :profile_id, :uuid

      change set_attribute(:room_id, arg(:room_id))
      change set_attribute(:content, arg(:content))
      change set_attribute(:role, arg(:role))
      change set_attribute(:message_type, :text)
      change set_attribute(:user_id, arg(:user_id))
      change set_attribute(:profile_id, arg(:profile_id))
      
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

    create :create_image_message do
      argument :room_id, :uuid, allow_nil?: false
      argument :content, :string, default: ""
      argument :image_url, :string
      argument :image_data, :binary
      argument :role, :atom, default: :user
      argument :user_id, :uuid
      argument :profile_id, :uuid

      change set_attribute(:room_id, arg(:room_id))
      change set_attribute(:content, arg(:content))
      change set_attribute(:role, arg(:role))
      change set_attribute(:message_type, :image)
      change set_attribute(:image_url, arg(:image_url))
      change set_attribute(:image_data, arg(:image_data))
      change set_attribute(:user_id, arg(:user_id))
      change set_attribute(:profile_id, arg(:profile_id))
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :destroy
    define :create_text_message
    define :create_image_message
    define :for_room
    define :semantic_search
  end
  
  # Simple SQLite persistence
  defp persist_to_sqlite(message) do
    case Exqlite.Sqlite3.open("ash_chat.db") do
      {:ok, conn} ->
        # Create table if not exists
        Exqlite.Sqlite3.execute(conn, """
        CREATE TABLE IF NOT EXISTS messages (
          id TEXT PRIMARY KEY,
          room_id TEXT NOT NULL,
          user_id TEXT,
          content TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
        """)
        
        # Insert message
        {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
        INSERT OR REPLACE INTO messages (id, room_id, user_id, content, role, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """)
        
        :ok = Exqlite.Sqlite3.bind(statement, [
          message.id,
          message.room_id,
          message.user_id || "",
          message.content,
          to_string(message.role),
          DateTime.to_iso8601(message.created_at)
        ])
        
        Exqlite.Sqlite3.step(conn, statement)
        Exqlite.Sqlite3.release(conn, statement)
        Exqlite.Sqlite3.close(conn)
      _ ->
        :ok  # Fail silently - don't break chat if DB is down
    end
  end
end