defmodule AshChat.AI.ContextAssemblerImprovements do
  @moduledoc """
  Improvements to the context assembler:
  - Event awareness: Include recent relevant events in context
  - Agent memory: Track patterns and discoveries across conversations
  - Dynamic prioritization: Adjust component priorities based on conversation flow
  """
  
  alias AshChat.Resources.Event
  alias AshChat.AI.ContextAssembler
  
  @doc """
  Add recent events to the context based on relevance
  """
  def add_relevant_events(assembler, agent_card, opts \\ []) do
    event_limit = Keyword.get(opts, :event_limit, 5)
    event_types = Keyword.get(opts, :event_types, ["discovery_moment", "pattern_detected"])
    
    # Get recent events from this agent or relevant to their interests
    relevant_events = get_relevant_events(agent_card, event_types, event_limit)
    
    if Enum.any?(relevant_events) do
      ContextAssembler.add_component(assembler, :recent_events, relevant_events,
        priority: 25,  # Between room context and conversation history
        metadata: %{
          event_count: length(relevant_events),
          source: "event_system",
          agent: agent_card.name
        }
      )
    else
      assembler
    end
  end
  
  @doc """
  Add agent's discovered patterns to context
  """
  def add_agent_patterns(assembler, agent_card, _opts \\ []) do
    # Get patterns this agent has detected
    pattern_events = get_agent_pattern_events(agent_card.name)
    
    if Enum.any?(pattern_events) do
      patterns = extract_patterns(pattern_events)
      
      ContextAssembler.add_component(assembler, :known_patterns, patterns,
        priority: 22,
        metadata: %{
          pattern_count: length(patterns),
          source: "agent_memory",
          agent: agent_card.name
        }
      )
    else
      assembler
    end
  end
  
  @doc """
  Add multi-agent interaction context
  """
  def add_multi_agent_context(assembler, room, agent_card, _opts \\ []) do
    # Get other agents in the room
    other_agents = get_other_agents_in_room(room.id, agent_card.id)
    
    if Enum.any?(other_agents) do
      agent_context = %{
        other_agents: Enum.map(other_agents, & &1.name),
        interaction_styles: build_interaction_styles(other_agents)
      }
      
      ContextAssembler.add_component(assembler, :multi_agent_context, agent_context,
        priority: 23,
        metadata: %{
          agent_count: length(other_agents),
          source: "room_agents"
        }
      )
    else
      assembler
    end
  end
  
  defp get_relevant_events(agent_card, event_types, limit) do
    case Event.read() do
      {:ok, events} ->
        events
        |> Enum.filter(fn event ->
          event.event_type in event_types ||
          String.contains?(event.source_id, agent_card.name) ||
          (is_map(event.metadata) && Map.get(event.metadata, "mentioned_agents", []) |> Enum.member?(agent_card.name))
        end)
        |> Enum.sort_by(& &1.timestamp, {:desc, DateTime})
        |> Enum.take(limit)
      
      _ -> []
    end
  end
  
  defp get_agent_pattern_events(agent_name) do
    case Event.by_event_type(%{event_type: "pattern_detected", limit: 50}) do
      {:ok, events} ->
        Enum.filter(events, fn event ->
          String.contains?(event.source_id, agent_name)
        end)
      
      _ -> []
    end
  end
  
  defp extract_patterns(pattern_events) do
    pattern_events
    |> Enum.map(fn event ->
      %{
        name: get_in(event.metadata, ["pattern_name"]) || "unnamed",
        instances: get_in(event.metadata, ["instance_count"]) || 1,
        discovered_at: event.timestamp
      }
    end)
    |> Enum.uniq_by(& &1.name)
  end
  
  defp get_other_agents_in_room(room_id, current_agent_id) do
    case AshChat.Resources.AgentMembership.for_room(%{room_id: room_id}) do
      {:ok, memberships} ->
        memberships
        |> Enum.reject(fn m -> m.agent_card_id == current_agent_id end)
        |> Enum.map(fn m -> m.agent_card end)
        |> Enum.filter(& &1)  # Remove any nil agent cards
      
      _ -> []
    end
  end
  
  defp build_interaction_styles(other_agents) do
    # Build a simple map of how to interact with each agent type
    Map.new(other_agents, fn agent ->
      {agent.name, suggest_interaction_style(agent)}
    end)
  end
  
  defp suggest_interaction_style(agent) do
    cond do
      String.contains?(String.downcase(agent.name), "curator") ->
        "Share patterns you notice for curation"
      
      String.contains?(String.downcase(agent.name), "observer") ->
        "Point out interesting moments for observation"
      
      String.contains?(String.downcase(agent.name), "contrarian") ->
        "Expect challenges to your assumptions"
      
      true ->
        "Collaborate on shared understanding"
    end
  end
  
  @doc """
  Convert new component types to messages
  """
  def convert_component_to_message(%{type: :recent_events, content: events}) do
    event_summaries = events
    |> Enum.map(fn event ->
      "- #{event.event_type}: #{event.description} (#{format_time_ago(event.timestamp)})"
    end)
    |> Enum.join("\n")
    
    content = "Recent relevant events:\n#{event_summaries}"
    
    %LangChain.Message{role: :system, content: content}
  end
  
  def convert_component_to_message(%{type: :known_patterns, content: patterns}) do
    pattern_list = patterns
    |> Enum.map(fn p ->
      "- '#{p.name}': #{p.instances} instances"
    end)
    |> Enum.join("\n")
    
    content = "Patterns you've discovered:\n#{pattern_list}"
    
    %LangChain.Message{role: :system, content: content}
  end
  
  def convert_component_to_message(%{type: :multi_agent_context, content: context}) do
    agent_list = context.other_agents |> Enum.join(", ")
    
    style_hints = context.interaction_styles
    |> Enum.map(fn {agent, style} ->
      "- #{agent}: #{style}"
    end)
    |> Enum.join("\n")
    
    content = """
    Other agents in this conversation: #{agent_list}
    
    Interaction notes:
    #{style_hints}
    """
    
    %LangChain.Message{role: :system, content: String.trim(content)}
  end
  
  defp format_time_ago(timestamp) do
    diff = DateTime.diff(DateTime.utc_now(), timestamp, :second)
    
    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end