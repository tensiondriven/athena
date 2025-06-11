# Minimal SQLite persistence for ash_chat
# Just persist messages first - the simplest, most valuable data

defmodule AddSQLite do
  @db_path "ash_chat.db"
  
  def setup do
    # Create messages table
    {:ok, conn} = Exqlite.Sqlite3.open(@db_path)
    
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
    
    IO.puts("✅ SQLite ready at #{@db_path}")
    Exqlite.Sqlite3.close(conn)
  end
end

# Test it
AddSQLite.setup()