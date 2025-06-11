# Test message persistence
alias AshChat.Resources.Message

# Create a test message
message = Message.create_text_message!(%{
  room_id: Ash.UUID.generate(),
  content: "Test persistence message at #{DateTime.utc_now()}",
  role: :user,
  user_id: Ash.UUID.generate()
})

IO.puts("Created message: #{message.id}")

# Wait for async persistence
Process.sleep(1000)

# Check database
{:ok, conn} = Exqlite.Sqlite3.open("ash_chat.db")
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT COUNT(*) FROM messages")
{:row, [count]} = Exqlite.Sqlite3.step(conn, statement)
Exqlite.Sqlite3.release(conn, statement)

IO.puts("Messages in database: #{count}")

# Show last message
{:ok, statement} = Exqlite.Sqlite3.prepare(conn, "SELECT content, created_at FROM messages ORDER BY created_at DESC LIMIT 1")
case Exqlite.Sqlite3.step(conn, statement) do
  {:row, [content, created_at]} ->
    IO.puts("Last message: '#{content}' at #{created_at}")
  _ ->
    IO.puts("No messages found")
end
Exqlite.Sqlite3.release(conn, statement)
Exqlite.Sqlite3.close(conn)