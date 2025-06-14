#!/usr/bin/env elixir

# Test script for multi-agent conversation functionality
# Run with: mix run test_multi_agent.exs

require Logger

defmodule MultiAgentTest do
  alias AshChat.Resources.{Room, User, Message, AgentMembership}
  alias AshChat.AI.{ChatAgent, AgentConversation}
  
  def run do
    Logger.info("Starting multi-agent test...")
    
    # Find the Conversation Lounge room
    rooms = Room.read!()
    conversation_room = Enum.find(rooms, fn r -> r.title == "Conversation Lounge" end)
    
    if conversation_room do
      Logger.info("Found Conversation Lounge room: #{conversation_room.id}")
      
      # Check agent memberships
      {:ok, memberships} = AgentMembership.for_room(%{room_id: conversation_room.id})
      Logger.info("Agent memberships in room: #{length(memberships)}")
      
      for membership <- memberships do
        {:ok, agent_card} = Ash.get(AshChat.Resources.AgentCard, membership.agent_card_id)
        Logger.info("  - #{agent_card.name} (auto_respond: #{membership.auto_respond})")
      end
      
      # Find Bob user
      users = User.read!()
      bob = Enum.find(users, fn u -> u.name == "Bob" end)
      
      if bob do
        Logger.info("Found Bob user: #{bob.id}")
        
        # Send a test message
        test_message = "Hey everyone! What's your favorite way to spend a weekend?"
        Logger.info("Sending test message: #{test_message}")
        
        # Create user message
        {:ok, user_message} = Message.create_text_message(%{
          room_id: conversation_room.id,
          content: test_message,
          role: :user,
          user_id: bob.id
        })
        
        Logger.info("User message created: #{user_message.id}")
        
        # Process agent responses
        Logger.info("Processing agent responses...")
        agent_responses = AgentConversation.process_agent_responses(
          conversation_room.id,
          user_message,
          [user_id: bob.id]
        )
        
        Logger.info("Got #{length(agent_responses)} agent responses")
        
        # Wait a bit for responses to be processed
        Process.sleep(3000)
        
        # Check messages in room
        {:ok, messages} = Message.for_room(%{room_id: conversation_room.id})
        recent_messages = messages |> Enum.take(-5)
        
        Logger.info("\nRecent messages in room:")
        for msg <- recent_messages do
          author = case msg.role do
            :user -> 
              {:ok, user} = Ash.get(User, msg.user_id)
              user.name
            :assistant -> 
              metadata = msg.metadata || %{}
              agent_id = Map.get(metadata, "agent_id")
              if agent_id do
                {:ok, agent} = Ash.get(AshChat.Resources.AgentCard, agent_id)
                "Agent: #{agent.name}"
              else
                "Assistant"
              end
          end
          
          Logger.info("  [#{author}]: #{String.slice(msg.content, 0, 100)}...")
        end
        
      else
        Logger.error("Could not find Bob user")
      end
    else
      Logger.error("Could not find Conversation Lounge room")
    end
  end
end

# Run the test
MultiAgentTest.run()