defmodule AshChat.AI.ConsciousnessLoop do
  @moduledoc """
  Integrates stance tracking, event generation, and context assembly
  into a unified consciousness loop for agents.
  
  The loop:
  1. Agent operates with current stance
  2. Significant discoveries/shifts generate events
  3. Events are preserved in the system
  4. Future context includes these events
  5. Context influences future stances
  """
  
  alias AshChat.AI.{StanceTracker, ContextAssembler, ContextAssemblerImprovements}
  alias AshChat.Resources.AgentCard
  require Logger
  
  defstruct agent_card: nil,
            stance_tracker: nil,
            metadata: %{}
  
  @doc """
  Initialize consciousness loop for an agent
  """
  def init(agent_card) do
    initial_stances = infer_initial_stances(agent_card)
    
    %__MODULE__{
      agent_card: agent_card,
      stance_tracker: StanceTracker.new(agent_card.name, initial_stances),
      metadata: %{initialized_at: DateTime.utc_now()}
    }
  end
  
  @doc """
  Build context with full consciousness integration
  """
  def build_context(consciousness, room, user_message, opts \\ []) do
    # Start with base context
    assembler = ContextAssembler.build_for_room(
      room,
      consciousness.agent_card,
      user_message,
      opts
    )
    
    # Add consciousness-aware components
    assembler
    |> add_stance_context(consciousness.stance_tracker)
    |> ContextAssemblerImprovements.add_relevant_events(consciousness.agent_card, opts)
    |> ContextAssemblerImprovements.add_agent_patterns(consciousness.agent_card, opts)
    |> ContextAssemblerImprovements.add_multi_agent_context(room, consciousness.agent_card, opts)
  end
  
  @doc """
  Process agent response and update consciousness
  """
  def process_response(consciousness, response_content, metadata \\ %{}) do
    # Analyze response for stance shifts
    stance_suggestions = StanceTracker.analyze_for_stance_shift(
      response_content,
      consciousness.stance_tracker
    )
    
    # Apply significant stance shifts
    updated_tracker = apply_stance_suggestions(
      consciousness.stance_tracker,
      stance_suggestions
    )
    
    # Detect patterns or discoveries in response
    detect_and_emit_events(consciousness.agent_card, response_content, metadata)
    
    %{consciousness | stance_tracker: updated_tracker}
  end
  
  defp infer_initial_stances(agent_card) do
    # Infer stances from agent's system message
    system_msg = String.downcase(agent_card.system_message || "")
    
    %{
      exploration: infer_exploration_stance(system_msg),
      implementation: infer_implementation_stance(system_msg),
      teaching: infer_teaching_stance(system_msg),
      revision: 50,  # Default balanced
      documentation: infer_documentation_stance(system_msg)
    }
  end
  
  defp infer_exploration_stance(msg) do
    cond do
      String.contains?(msg, ["curious", "explore", "discover"]) -> 75
      String.contains?(msg, ["critical", "analyze", "flaw"]) -> 25
      true -> 50
    end
  end
  
  defp infer_implementation_stance(msg) do
    cond do
      String.contains?(msg, ["creative", "experiment", "try"]) -> 75
      String.contains?(msg, ["focus", "specific", "precise"]) -> 25
      true -> 50
    end
  end
  
  defp infer_teaching_stance(msg) do
    cond do
      String.contains?(msg, ["patient", "guide", "help understand"]) -> 75
      String.contains?(msg, ["direct", "concise", "brief"]) -> 25
      true -> 50
    end
  end
  
  defp infer_documentation_stance(msg) do
    cond do
      String.contains?(msg, ["clear", "simple", "concise"]) -> 75
      String.contains?(msg, ["comprehensive", "complete", "detailed"]) -> 25
      true -> 50
    end
  end
  
  defp add_stance_context(assembler, stance_tracker) do
    stance_description = """
    Current operational stance: #{StanceTracker.to_notation(stance_tracker)}
    #{StanceTracker.describe_stances(stance_tracker)}
    """
    
    ContextAssembler.add_component(assembler, :stance_context, stance_description,
      priority: 15,
      metadata: %{source: "consciousness_loop"}
    )
  end
  
  defp apply_stance_suggestions(tracker, suggestions) do
    Enum.reduce(suggestions, tracker, fn {stance, value}, acc ->
      case StanceTracker.update_stance(acc, stance, value) do
        {:ok, updated} -> updated
        _ -> acc
      end
    end)
  end
  
  defp detect_and_emit_events(agent_card, content, metadata) do
    # TODO: Integrate with EventGenerator when available
    cond do
      String.contains?(content, ["oh!", "aha!", "discovered", "realized"]) ->
        Logger.info("Discovery moment detected for #{agent_card.name}")
        # EventGenerator.discovery_moment(agent_card.name, content, metadata)
      
      String.contains?(content, ["pattern", "recurring", "noticed repeatedly"]) ->
        Logger.info("Pattern detected by #{agent_card.name}")
        # EventGenerator.pattern_detected(agent_card.name, "unnamed", 2, metadata)
      
      String.contains?(content, ["comprehensive", "utilizing", "leverage"]) ->
        Logger.info("Slop detected by #{agent_card.name}")
        # EventGenerator.slop_detected(agent_card.name, content, metadata)
      
      true ->
        nil
    end
  end
end