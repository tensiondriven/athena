defmodule AshChat.AI.AgentConversation do
  @moduledoc """
  Handles agent-to-agent conversations with loop prevention and selective responses
  """
  
  alias AshChat.Resources.{Message, AgentMembership, AgentCard}
  alias AshChat.AI.ChatAgent
  require Logger
  
  @doc """
  Check if an agent should respond to a message based on:
  - Message content relevance
  - Conversation context
  - Loop prevention
  - Agent's decision-making
  """
  def should_agent_respond?(agent_card, message, room_id) do
    # Don't respond to system messages
    if message.role == :system do
      false
    else
      # For assistant messages, only respond if it's from a different agent
      if message.role == :assistant do
        # Check if this message is from a different agent
        message_agent_id = get_in(message.metadata || %{}, ["agent_id"]) || get_in(message.metadata || %{}, [:agent_id])
        
        if message_agent_id == agent_card.id do
          # Don't respond to our own messages
          false
        else
          # This is from another agent, check for loops and decide
          check_and_respond(agent_card, message, room_id)
        end
      else
        # User message, check normally
        check_and_respond(agent_card, message, room_id)
      end
    end
  end
  
  defp check_and_respond(agent_card, message, room_id) do
    # Get recent conversation context
    recent_messages = get_recent_messages(room_id, 5)
    
    # Check for conversation loops
    if detecting_loop?(recent_messages, agent_card.id) do
      Logger.info("Loop detected for agent #{agent_card.name}, skipping response")
      false
    else
      # Let the agent decide if it should respond
      agent_wants_to_respond?(agent_card, message, recent_messages)
    end
  end
  
  @doc """
  Process room join and trigger agent welcome responses
  """
  def process_room_join_responses(room_id, user) do
    # Get all auto-responding agents for this room
    case AgentMembership.auto_responders_for_room(%{room_id: room_id}) do
      {:ok, agent_memberships} ->
        # Process each agent in parallel
        tasks = for agent_membership <- agent_memberships do
          Task.async(fn ->
            case Ash.get(AgentCard, agent_membership.agent_card_id) do
              {:ok, agent_card} ->
                # Create a synthetic "join" message for context
                join_context = "#{user.display_name || user.name} has joined the conversation."
                generate_welcome_response(agent_card, room_id, join_context)
              {:error, _} ->
                nil
            end
          end)
        end
        
        # Collect responses with timeout
        tasks
        |> Task.yield_many(8000)  # Longer timeout for welcome responses
        |> Enum.map(fn {task, res} ->
          case res do
            {:ok, response} -> response
            _ -> 
              Task.shutdown(task, :brutal_kill)
              nil
          end
        end)
        |> Enum.filter(&(&1 != nil))
        
      {:error, error} ->
        Logger.error("Failed to get auto-responding agents for room join: #{inspect(error)}")
        []
    end
  end

  @doc """
  Process a message and determine which agents should respond
  Returns list of agent responses to be sent
  """
  def process_agent_responses(room_id, trigger_message, opts \\ []) do
    Logger.debug("AgentConversation.process_agent_responses for room #{room_id}")
    
    # Get all auto-responding agents for this room
    case AgentMembership.auto_responders_for_room(%{room_id: room_id}) do
      {:ok, agent_memberships} ->
        Logger.debug("Found #{length(agent_memberships)} auto-responding agents")
        
        # Process each agent in parallel
        tasks = for agent_membership <- agent_memberships do
          Task.async(fn ->
            case Ash.get(AgentCard, agent_membership.agent_card_id) do
              {:ok, agent_card} ->
                Logger.debug("Checking if #{agent_card.name} should respond")
                if should_agent_respond?(agent_card, trigger_message, room_id) do
                  Logger.debug("#{agent_card.name} will respond")
                  generate_agent_response(agent_card, room_id, trigger_message, opts)
                else
                  Logger.debug("#{agent_card.name} will not respond")
                  nil
                end
              {:error, error} ->
                Logger.error("Failed to get agent card: #{inspect(error)}")
                nil
            end
          end)
        end
        
        # Collect responses (with timeout)
        tasks
        |> Task.yield_many(5000)
        |> Enum.map(fn {task, res} ->
          case res do
            {:ok, response} -> response
            _ -> 
              Task.shutdown(task, :brutal_kill)
              nil
          end
        end)
        |> Enum.filter(&(&1 != nil))
        
      {:error, error} ->
        Logger.error("Failed to get auto-responding agents: #{inspect(error)}")
        []
    end
  end
  
  defp get_recent_messages(room_id, limit) do
    case Message.for_room(%{room_id: room_id}) do
      {:ok, messages} ->
        messages
        |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
        |> Enum.take(limit)
        |> Enum.reverse()
      _ ->
        []
    end
  end
  
  defp detecting_loop?(recent_messages, agent_id) do
    # Improved loop detection: Check if agent is responding repeatedly without user input
    # Look at the last few messages to see if there's a pattern of agent-only conversation
    
    last_messages = Enum.take(recent_messages, -5)
    
    # If there are less than 2 messages, no loop possible
    if length(last_messages) < 2 do
      false
    else
      # Check if the last 2 assistant messages are from the same agent with no user message between
      assistant_messages = last_messages
      |> Enum.with_index()
      |> Enum.filter(fn {msg, _idx} -> 
        msg.role == :assistant && 
        msg.metadata && 
        Map.get(msg.metadata, "agent_id") == agent_id
      end)
      
      case assistant_messages do
        # If we have 2+ consecutive assistant messages from this agent, check for user input between
        [{_msg1, idx1}, {_msg2, idx2} | _] when idx2 == idx1 + 1 ->
          # Two consecutive messages from same agent - that's a loop
          true
        _ ->
          # Otherwise, no loop detected
          false
      end
    end
  end
  
  @doc """
  Manually trigger an agent to send a message or respond
  """
  def trigger_agent_response(agent_card_id, room_id, content \\ nil) do
    with {:ok, agent_card} <- Ash.get(AgentCard, agent_card_id) do
      if content do
        # Agent initiates with specific content
        create_agent_message(agent_card, room_id, content)
      else
        # Agent responds to last message
        recent_messages = get_recent_messages(room_id, 10)
        last_message = List.last(recent_messages)
        
        if last_message do
          response = generate_agent_response(agent_card, room_id, last_message, [])
          
          if response do
            create_agent_message(agent_card, room_id, response.content)
          else
            {:error, "Agent chose not to respond"}
          end
        else
          {:error, "No messages to respond to"}
        end
      end
    end
  end
  
  defp create_agent_message(agent_card, room_id, content) do
    Message.create_text_message(%{
      room_id: room_id,
      role: :assistant,
      content: content,
      metadata: %{
        agent_id: agent_card.id,
        agent_name: agent_card.name,
        triggered_manually: true
      }
    })
  end
  
  defp agent_wants_to_respond?(agent_card, message, _recent_messages) do
    # For now, simple heuristic - agent responds if:
    # 1. Message mentions their name
    # 2. Message is asking a question
    # 3. Random chance (to keep conversation flowing)
    
    message_text = String.downcase(message.content)
    agent_name = String.downcase(agent_card.name)
    
    cond do
      # Mentioned by name
      String.contains?(message_text, agent_name) ->
        true
        
      # Question directed at agents
      String.ends_with?(message_text, "?") ->
        # 70% chance to respond to questions
        :rand.uniform() < 0.7
        
      # General statement
      true ->
        # 30% chance to respond to statements
        :rand.uniform() < 0.3
    end
  end
  
  defp generate_agent_response(agent_card, room_id, trigger_message, opts) do
    # Get room
    case Ash.get(AshChat.Resources.Room, room_id) do
      {:ok, room} ->
        # Generate response using the agent card
        # Note: process_message_with_agent_card creates the message and broadcasts it
        case ChatAgent.process_message_with_agent_card(
          room,
          trigger_message.content,
          agent_card,
          opts ++ [metadata: %{"agent_id" => agent_card.id}]
        ) do
          {:ok, response_content} ->
            %{
              agent_card: agent_card,
              content: response_content,
              delay_ms: 200  # As per user requirement
            }
          {:error, error} ->
            Logger.error("Failed to generate response for agent #{agent_card.name}: #{inspect(error)}")
            nil
        end
        
      {:error, _} ->
        nil
    end
  end
  
  defp generate_welcome_response(agent_card, room_id, join_context) do
    # Get room
    case Ash.get(AshChat.Resources.Room, room_id) do
      {:ok, room} ->
        # Generate welcome response
        case ChatAgent.process_message_with_agent_card(
          room,
          join_context,
          agent_card,
          [metadata: %{"agent_id" => agent_card.id, "type" => "welcome"}]
        ) do
          {:ok, response_content} ->
            Logger.info("Agent #{agent_card.name} generated welcome: #{String.slice(response_content, 0, 50)}...")
            %{
              agent_card: agent_card,
              content: response_content,
              delay_ms: 1000  # Slightly longer delay for welcome
            }
          {:error, error} ->
            Logger.error("Failed to generate welcome for agent #{agent_card.name}: #{inspect(error)}")
            nil
        end
        
      {:error, _} ->
        nil
    end
  end
end