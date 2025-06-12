defmodule AshChat.AI.StanceTracker do
  @moduledoc """
  Tracks agent stances based on the stance polarities framework.
  
  Stances represent operational modes:
  - Exploration (Open vs Critical)
  - Implementation (Convergent vs Divergent) 
  - Teaching (Patient vs Direct)
  - Revision (Preserve vs Transform)
  - Documentation (Clear vs Complete)
  
  Each stance is tracked on a 0-100 scale between polarities.
  """
  
  require Logger
  
  @stance_definitions %{
    exploration: %{
      low: "Critical",
      high: "Open",
      description: "How open vs critical in exploring ideas"
    },
    implementation: %{
      low: "Convergent", 
      high: "Divergent",
      description: "Focused execution vs creative expansion"
    },
    teaching: %{
      low: "Direct",
      high: "Patient", 
      description: "Quick answers vs guided discovery"
    },
    revision: %{
      low: "Transform",
      high: "Preserve",
      description: "Major changes vs minor tweaks"
    },
    documentation: %{
      low: "Complete",
      high: "Clear",
      description: "Comprehensive vs accessible"
    }
  }
  
  defstruct agent_name: nil,
            stances: %{
              exploration: 50,
              implementation: 50,
              teaching: 50,
              revision: 50,
              documentation: 50
            },
            metadata: %{}
  
  @doc """
  Create a new stance tracker for an agent
  """
  def new(agent_name, initial_stances \\ %{}) do
    %__MODULE__{
      agent_name: agent_name,
      stances: Map.merge(%{
        exploration: 50,
        implementation: 50,
        teaching: 50,
        revision: 50,
        documentation: 50
      }, initial_stances),
      metadata: %{created_at: DateTime.utc_now()}
    }
  end
  
  @doc """
  Update a stance value and potentially generate an event
  """
  def update_stance(tracker, stance_type, new_value) when new_value >= 0 and new_value <= 100 do
    old_value = Map.get(tracker.stances, stance_type, 50)
    
    # Only update if change is significant (>10 points)
    if abs(new_value - old_value) > 10 do
      new_stances = Map.put(tracker.stances, stance_type, new_value)
      updated_tracker = %{tracker | stances: new_stances}
      
      # Generate event for significant shifts
      # TODO: Uncomment when EventGenerator is available
      # from_desc = describe_stance_value(stance_type, old_value)
      # to_desc = describe_stance_value(stance_type, new_value)
      
      # EventGenerator.stance_shift(
      #   tracker.agent_name,
      #   {stance_type, from_desc},
      #   {stance_type, to_desc},
      #   %{
      #     old_value: old_value,
      #     new_value: new_value,
      #     shift_magnitude: new_value - old_value
      #   }
      # )
      
      Logger.info("Stance shift: #{tracker.agent_name} #{stance_type} #{old_value} -> #{new_value}")
      
      {:ok, updated_tracker}
    else
      {:ok, tracker}
    end
  end
  
  @doc """
  Get a human-readable description of current stances
  """
  def describe_stances(tracker) do
    tracker.stances
    |> Enum.map(fn {stance, value} ->
      desc = describe_stance_value(stance, value)
      "#{stance}: #{desc} (#{value})"
    end)
    |> Enum.join(", ")
  end
  
  @doc """
  Detect if agent is in an "impossible stance" (multiple extremes)
  """
  def detect_impossible_stance(tracker) do
    extreme_stances = tracker.stances
    |> Enum.filter(fn {_stance, value} ->
      value <= 10 || value >= 90
    end)
    
    if length(extreme_stances) >= 2 do
      {:impossible_stance, extreme_stances}
    else
      :normal
    end
  end
  
  @doc """
  Get stance notation (compact representation)
  """
  def to_notation(tracker) do
    # O75 P25 Cr60 Pr40 L80
    %{
      exploration: o,
      implementation: p,
      teaching: cr,
      revision: pr,
      documentation: l
    } = tracker.stances
    
    "O#{o} P#{p} Cr#{cr} Pr#{pr} L#{l}"
  end
  
  defp describe_stance_value(stance_type, value) do
    definition = Map.get(@stance_definitions, stance_type)
    
    cond do
      value <= 20 -> "Very #{definition.low}"
      value <= 40 -> definition.low
      value <= 60 -> "Balanced"
      value <= 80 -> definition.high
      true -> "Very #{definition.high}"
    end
  end
  
  @doc """
  Analyze message content to suggest stance adjustments
  """
  def analyze_for_stance_shift(content, current_tracker) do
    suggestions = []
    
    # Exploration stance indicators
    suggestions = suggestions ++ 
      cond do
        String.contains?(content, ["what if", "curious", "wonder", "explore"]) ->
          [{:exploration, min(current_tracker.stances.exploration + 15, 100)}]
        String.contains?(content, ["wrong", "flaw", "issue", "problem"]) ->
          [{:exploration, max(current_tracker.stances.exploration - 15, 0)}]
        true -> []
      end
    
    # Implementation stance indicators  
    suggestions = suggestions ++
      cond do
        String.contains?(content, ["let's try", "experiment", "multiple"]) ->
          [{:implementation, min(current_tracker.stances.implementation + 15, 100)}]
        String.contains?(content, ["focus", "specific", "exactly"]) ->
          [{:implementation, max(current_tracker.stances.implementation - 15, 0)}]
        true -> []
      end
    
    suggestions
  end
end