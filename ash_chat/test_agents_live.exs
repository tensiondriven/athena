#!/usr/bin/env elixir

# Script to test multi-agent functionality by simulating browser interaction
# Run with: mix run test_agents_live.exs

defmodule TestAgentsLive do
  require Logger
  
  def run do
    Logger.info("Testing multi-agent chat via HTTP...")
    
    # First, let's check what rooms are available in the UI
    case :httpc.request(:get, {'http://localhost:4000/chat', []}, [], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        body_str = to_string(body)
        
        # Find room titles and IDs from the HTML
        room_pattern = ~r/phx-value-room-id="([^"]+)"[^>]*>[^<]*<span[^>]*>([^<]+)<\/span>/
        rooms = Regex.scan(room_pattern, body_str)
        
        Logger.info("Found #{length(rooms)} rooms in the UI")
        
        conversation_room = Enum.find(rooms, fn [_, _, title] -> 
          String.contains?(title, "Conversation")
        end)
        
        if conversation_room do
          [_, room_id, title] = conversation_room
          Logger.info("Found room: #{title} (ID: #{room_id})")
          
          # Now we need to check if this room has agents
          # Unfortunately, we can't easily trigger LiveView events from outside
          # So let's provide instructions for manual testing
          
          Logger.info("""
          
          ==========================================
          MANUAL TEST INSTRUCTIONS:
          ==========================================
          
          1. Open your browser and navigate to: http://localhost:4000/chat
          
          2. Click on the "Conversation Lounge" room (ID: #{room_id})
          
          3. Send a message like: "Hello everyone! What's your favorite weekend activity?"
          
          4. Watch the server logs for agent responses. You should see:
             - Log messages showing agents (Sam and Maya) processing the message
             - Agent responses appearing in the chat
          
          5. To monitor the logs, run in another terminal:
             tail -f server.log | grep -E "(agent|Agent|Sam|Maya|responded)"
          
          ==========================================
          
          The multi-agent system is designed to have agents respond to messages with:
          - 70% chance to respond to questions (ending with ?)
          - 30% chance to respond to statements
          - Always respond if mentioned by name
          - Loop prevention to avoid infinite conversations
          
          """)
        else
          Logger.error("Could not find Conversation room in the UI")
        end
        
      {:error, reason} ->
        Logger.error("Failed to fetch chat page: #{inspect(reason)}")
    end
  end
end

# Start inets for HTTP client
:inets.start()
TestAgentsLive.run()