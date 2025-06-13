defmodule AshChat.AI.EventGenerator do
  @moduledoc """
  Generates events from agent activities and conversations
  """
  
  alias AshChat.Resources.Event
  require Logger
  
  @doc """
  Generate an event when an agent has a discovery moment
  """
  def discovery_moment(agent_name, content, metadata \\ %{}) do
    create_agent_event(
      "discovery_moment",
      agent_name,
      content,
      "#{agent_name} had an 'oh!' moment",
      0.85,
      metadata
    )
  end
  
  @doc """
  Generate an event when an agent detects a pattern
  """
  def pattern_detected(agent_name, pattern_name, instances, metadata \\ %{}) do
    create_agent_event(
      "pattern_detected",
      agent_name,
      "Pattern '#{pattern_name}' detected with #{instances} instances",
      "#{agent_name} identified recurring pattern: #{pattern_name}",
      0.9,
      Map.merge(metadata, %{pattern_name: pattern_name, instance_count: instances})
    )
  end
  
  @doc """
  Generate an event when agents interact with each other
  """
  def multi_agent_interaction(initiator, responder, context, metadata \\ %{}) do
    create_agent_event(
      "multi_agent_interaction",
      "#{initiator}->#{responder}",
      context,
      "#{initiator} triggered response from #{responder}",
      0.95,
      Map.merge(metadata, %{initiator: initiator, responder: responder})
    )
  end
  
  @doc """
  Generate an event when slop is detected
  """
  def slop_detected(agent_name, slop_content, metadata \\ %{}) do
    create_agent_event(
      "slop_detected",
      agent_name,
      slop_content,
      "#{agent_name} flagged generic content",
      0.8,
      metadata
    )
  end
  
  @doc """
  Generate an event when an agent's stance shifts
  """
  def stance_shift(agent_name, from_stance, to_stance, metadata \\ %{}) do
    create_agent_event(
      "stance_shift",
      agent_name,
      "Stance shifted from #{inspect(from_stance)} to #{inspect(to_stance)}",
      "#{agent_name} changed operational stance",
      0.75,
      Map.merge(metadata, %{from_stance: from_stance, to_stance: to_stance})
    )
  end
  
  @doc """
  Generate an event when a user joins a room
  """
  def room_join(user_name, room_title, metadata \\ %{}) do
    create_agent_event(
      "room_join",
      "room_system",
      "#{user_name} joined #{room_title}",
      "User entered the conversation space",
      1.0,
      Map.merge(metadata, %{event_type: "room_join", user_name: user_name, room_title: room_title})
    )
  end
  
  defp create_agent_event(event_type, source_id, content, description, confidence, metadata) do
    event_args = %{
      timestamp: DateTime.utc_now(),
      event_type: event_type,
      source_id: "agent:#{source_id}",
      source_path: "/athena/agents/#{source_id}",
      content: content,
      confidence: confidence,
      description: description,
      metadata: Map.merge(metadata, %{
        generated_by: "agent_event_generator",
        agent_source: true
      })
    }
    
    case Event.create(event_args) do
      {:ok, event} ->
        Logger.info("Agent event created: #{event_type} from #{source_id}")
        
        # Broadcast to dashboard
        Phoenix.PubSub.broadcast(
          AshChat.PubSub, 
          "events", 
          {:new_event, event}
        )
        
        {:ok, event}
        
      {:error, error} ->
        Logger.error("Failed to create agent event: #{inspect(error)}")
        {:error, error}
    end
  end
end