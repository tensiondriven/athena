# Quick test to send a message and see what happens
# Run with: elixir quick_chat_test.exs (while server is running)

# Connect to running app
:net_adm.ping(:'ash_chat@localhost')
Node.connect(:'ash_chat@localhost')

# Run the test remotely
result = :rpc.call(:'ash_chat@localhost', :elixir, :eval_string, ["""
  alias AshChat.Resources.{Room, User, Message}
  
  # Get first room and user
  {:ok, [room | _]} = Room.read()
  {:ok, [user | _]} = User.read()
  
  IO.puts("Testing in room: \#{room.title}")
  IO.puts("As user: \#{user.display_name}")
  
  # Create a message
  {:ok, msg} = Message.create_text_message(%{
    room_id: room.id,
    content: "Test message at \#{DateTime.utc_now()}",
    role: :user,
    user_id: user.id
  })
  
  IO.puts("Created message: \#{msg.id}")
  
  # Wait and check
  Process.sleep(3000)
  
  {:ok, messages} = Message.for_room(%{room_id: room.id})
  IO.puts("Total messages: \#{length(messages)}")
  
  # Return last few messages
  messages
  |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
  |> Enum.take(3)
  |> Enum.map(fn m -> 
    %{role: m.role, content: String.slice(m.content, 0, 50)}
  end)
"""])

IO.inspect(result, label: "Result")