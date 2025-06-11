# Test room persistence
alias AshChat.Resources.Room

# Check if ash_chat.db exists
db_exists = File.exists?("ash_chat.db")
IO.puts("Database exists: #{db_exists}")

# Create a test room
room = Room.create!(%{
  name: "Persistence Test Room #{:os.system_time(:millisecond)}",
  description: "Testing minimal persistence"
})

IO.puts("Created room: #{room.name} (#{room.id})")

# Add minimal room persistence
defmodule RoomPersistence do
  def persist_room(room) do
    case Exqlite.Sqlite3.open("ash_chat.db") do
      {:ok, conn} ->
        # Create rooms table if not exists
        Exqlite.Sqlite3.execute(conn, """
        CREATE TABLE IF NOT EXISTS rooms (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL
        )
        """)
        
        # Insert room
        {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
        INSERT OR REPLACE INTO rooms (id, name, description, created_at)
        VALUES (?, ?, ?, ?)
        """)
        
        :ok = Exqlite.Sqlite3.bind(statement, [
          room.id,
          room.name,
          room.description || "",
          DateTime.to_iso8601(room.created_at)
        ])
        
        Exqlite.Sqlite3.step(conn, statement)
        Exqlite.Sqlite3.release(conn, statement)
        Exqlite.Sqlite3.close(conn)
        
        IO.puts("Room persisted to SQLite")
      _ ->
        IO.puts("Failed to open database")
    end
  end
end

# Persist the room
RoomPersistence.persist_room(room)

# Check what's in the database
{:ok, conn} = Exqlite.Sqlite3.open("ash_chat.db")
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT COUNT(*) FROM rooms")
{:row, [count]} = Exqlite.Sqlite3.step(conn, statement)
Exqlite.Sqlite3.release(conn, statement)
Exqlite.Sqlite3.close(conn)

IO.puts("Total rooms in database: #{count}")