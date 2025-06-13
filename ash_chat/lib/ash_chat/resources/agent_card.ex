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
    attribute :model_preferences, :map, public?: true, default: %{} # temperature, top_p, etc.
    attribute :available_tools, {:array, :string}, public?: true, default: [] # tool names this agent can use
    attribute :context_settings, :map, public?: true, default: %{} # history_limit, vector_search, etc.
    attribute :avatar_url, :string, public?: true # Optional character avatar
    attribute :is_default, :boolean, default: false, public?: true
    attribute :add_to_new_rooms, :boolean, default: false, public?: true # Auto-join new rooms
    attribute :default_persona_id, :uuid, public?: true # Which persona this agent prefers
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :system_prompt, AshChat.Resources.SystemPrompt do
      public? true
      allow_nil? false
      description "The system prompt this agent uses"
    end

    belongs_to :default_persona, AshChat.Resources.Persona do
      source_attribute :default_persona_id
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
    validate present(:system_prompt_id), message: "System prompt is required"
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :description, :system_prompt_id, :model_preferences, 
              :available_tools, :context_settings, :avatar_url, :is_default, :add_to_new_rooms, :default_persona_id]
      
      change fn changeset, _context ->
        # If this is being set as default, unset other defaults
        if Ash.Changeset.get_attribute(changeset, :is_default) do
          # TODO: Clear other defaults in a proper change
          changeset
        else
          changeset
        end
      end
      
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
  
  # Simple SQLite persistence
  defp persist_to_sqlite(agent_card) do
    case Exqlite.Sqlite3.open("ash_chat.db") do
      {:ok, conn} ->
        # Create table if not exists
        Exqlite.Sqlite3.execute(conn, """
        CREATE TABLE IF NOT EXISTS agent_cards (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          system_prompt_id TEXT NOT NULL,
          model_preferences TEXT,
          available_tools TEXT,
          context_settings TEXT,
          avatar_url TEXT,
          is_default INTEGER DEFAULT 0,
          add_to_new_rooms INTEGER DEFAULT 0,
          default_profile_id TEXT,
          created_at TEXT NOT NULL
        )
        """)
        
        # Insert agent_card
        {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
        INSERT OR REPLACE INTO agent_cards 
        (id, name, description, system_prompt_id, model_preferences, available_tools, 
         context_settings, avatar_url, is_default, add_to_new_rooms, default_profile_id, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """)
        
        :ok = Exqlite.Sqlite3.bind(statement, [
          agent_card.id,
          agent_card.name,
          agent_card.description || "",
          agent_card.system_prompt_id,
          Jason.encode!(agent_card.model_preferences || %{}),
          Jason.encode!(agent_card.available_tools || []),
          Jason.encode!(agent_card.context_settings || %{}),
          agent_card.avatar_url || "",
          if(agent_card.is_default, do: 1, else: 0),
          if(agent_card.add_to_new_rooms, do: 1, else: 0),
          agent_card.default_profile_id || "",
          DateTime.to_iso8601(agent_card.created_at)
        ])
        
        Exqlite.Sqlite3.step(conn, statement)
        Exqlite.Sqlite3.release(conn, statement)
        Exqlite.Sqlite3.close(conn)
      _ ->
        :ok  # Fail silently - don't break chat if DB is down
    end
  end
end