#!/usr/bin/env elixir

# This script runs in the Phoenix server context using remote console
# Run with: elixir test_in_phoenix_context.exs

IO.puts("Connecting to running Phoenix server...")

# Connect to the running node
node_name = :"ash_chat@127.0.0.1"
cookie = String.to_atom(System.get_env("RELEASE_COOKIE", "ash_chat_cookie"))

# Set our node name and cookie
Node.start(:"test_script@127.0.0.1")
Node.set_cookie(cookie)

case Node.connect(node_name) do
  true ->
    IO.puts("Connected to #{node_name}")
    
    # Run code on the remote node
    :rpc.call(node_name, IO, :puts, ["Remote execution successful!"])
    
    # Test the conversation
    result = :rpc.call(node_name, fn ->
      require Logger
      
      # Find Conversation Lounge
      rooms = AshChat.Resources.Room.read!()
      lounge = Enum.find(rooms, fn r -> r.title == "Conversation Lounge" end)
      
      if lounge do
        # Find Jonathan
        users = AshChat.Resources.User.read!()
        jonathan = Enum.find(users, fn u -> u.name == "Jonathan" end)
        
        if jonathan do
          # Send message
          {:ok, msg} = AshChat.Resources.Message.create_text_message(%{
            room_id: lounge.id,
            content: "Testing AI agents - Sam and Maya, what's your take on the future of work?",
            role: :user,
            user_id: jonathan.id
          })
          
          # Process responses
          responses = AshChat.AI.AgentConversation.process_agent_responses(
            lounge.id,
            msg,
            [user_id: jonathan.id]
          )
          
          {:ok, length(responses)}
        else
          {:error, "Jonathan not found"}
        end
      else
        {:error, "Conversation Lounge not found"}
      end
    end, [])
    
    IO.inspect(result, label: "Result")
    
  false ->
    IO.puts("Failed to connect to #{node_name}")
    IO.puts("Is the Phoenix server running with --name #{node_name}?")
end