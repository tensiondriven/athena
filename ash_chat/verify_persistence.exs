# Verify all persistence is working
IO.puts("=== Persistence Verification Script ===\n")

# Check database exists
db_exists = File.exists?("ash_chat.db")
IO.puts("Database exists: #{db_exists}")

if db_exists do
  {:ok, conn} = Exqlite.Sqlite3.open("ash_chat.db")
  
  # Check all tables
  tables = ["messages", "rooms", "users", "agent_cards"]
  
  for table <- tables do
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT COUNT(*) FROM #{table}")
    case Exqlite.Sqlite3.step(conn, statement) do
      {:row, [count]} ->
        IO.puts("#{String.pad_trailing(table, 12)}: #{count} records")
      _ ->
        IO.puts("#{String.pad_trailing(table, 12)}: table not found")
    end
    Exqlite.Sqlite3.release(conn, statement)
  end
  
  IO.puts("\n=== Sample Data ===")
  
  # Show latest message
  {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    SELECT content, role, created_at 
    FROM messages 
    ORDER BY created_at DESC 
    LIMIT 1
  """)
  case Exqlite.Sqlite3.step(conn, statement) do
    {:row, [content, role, created_at]} ->
      IO.puts("\nLatest message:")
      IO.puts("  Content: #{content}")
      IO.puts("  Role: #{role}")
      IO.puts("  Created: #{created_at}")
    _ ->
      IO.puts("\nNo messages found")
  end
  Exqlite.Sqlite3.release(conn, statement)
  
  # Define reusable fetch function
  fetch_all = fn stmt, conn, fetch_fn ->
    case Exqlite.Sqlite3.step(conn, stmt) do
      {:row, row} -> [row | fetch_fn.(stmt, conn, fetch_fn)]
      _ -> []
    end
  end
  
  # Show rooms
  {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    SELECT title, created_at 
    FROM rooms 
    ORDER BY created_at DESC 
    LIMIT 3
  """)
  IO.puts("\nRecent rooms:")
  rows = fetch_all.(statement, conn, fetch_all)
  for [title, created_at] <- rows do
    IO.puts("  - #{title} (#{created_at})")
  end
  Exqlite.Sqlite3.release(conn, statement)
  
  # Show users
  {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    SELECT name, display_name 
    FROM users 
    ORDER BY created_at DESC 
    LIMIT 3
  """)
  IO.puts("\nRecent users:")
  rows = fetch_all.(statement, conn, fetch_all)
  for [name, display_name] <- rows do
    IO.puts("  - #{name} (#{display_name})")
  end
  Exqlite.Sqlite3.release(conn, statement)
  
  # Show agent cards
  {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    SELECT name, description 
    FROM agent_cards 
    ORDER BY created_at DESC 
    LIMIT 3
  """)
  IO.puts("\nRecent agent cards:")
  rows = fetch_all.(statement, conn, fetch_all)
  for [name, description] <- rows do
    IO.puts("  - #{name}: #{description}")
  end
  Exqlite.Sqlite3.release(conn, statement)
  
  Exqlite.Sqlite3.close(conn)
  
  IO.puts("\n✅ Persistence verification complete!")
else
  IO.puts("\n❌ No database found. Run the chat application first to create it.")
end