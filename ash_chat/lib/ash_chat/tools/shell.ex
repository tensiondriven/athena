defmodule AshChat.Tools.Shell do
  @moduledoc """
  Shell command execution tool with whitelist and event tracking
  """
  
  alias AshChat.Resources.Event
  require Logger
  
  @whitelisted_commands ~w(ls pwd echo date whoami ps df cd)
  
  @doc """
  Execute a shell command if it's whitelisted, creating events for tracking.
  Returns {:ok, output} or {:error, reason}
  """
  def execute(command, context \\ %{}) do
    parsed = parse_command(command)
    
    case validate_command(parsed) do
      :ok ->
        execute_and_track(command, parsed, context)
        
      {:error, :not_whitelisted} ->
        # Create event for denied command
        create_event("tool_call_denied", %{
          tool: "shell_command",
          command: command,
          reason: "not_whitelisted",
          allowed_commands: @whitelisted_commands
        }, context)
        
        {:error, {:not_whitelisted, @whitelisted_commands}}
        
      error ->
        error
    end
  end
  
  @doc """
  Get the list of whitelisted commands
  """
  def whitelisted_commands, do: @whitelisted_commands
  
  defp parse_command(command) when is_binary(command) do
    command
    |> String.trim()
    |> String.split(" ", parts: 2)
    |> case do
      [cmd] -> {cmd, []}
      [cmd, args] -> {cmd, args}
      _ -> {"", []}
    end
  end
  
  defp validate_command({"", _}), do: {:error, :empty_command}
  defp validate_command({cmd, _args}) do
    if cmd in @whitelisted_commands do
      :ok
    else
      {:error, :not_whitelisted}
    end
  end
  
  defp execute_and_track(command, _parsed, context) do
    start_time = System.monotonic_time(:millisecond)
    
    # Create start event
    create_event("tool_call_started", %{
      tool: "shell_command",
      command: command
    }, context)
    
    # Execute the command
    result = System.cmd("sh", ["-c", command], stderr_to_stdout: true)
    
    duration_ms = System.monotonic_time(:millisecond) - start_time
    
    case result do
      {output, 0} ->
        # Success event
        create_event("tool_call_completed", %{
          tool: "shell_command",
          command: command,
          output: truncate_output(output),
          exit_code: 0,
          duration_ms: duration_ms
        }, context)
        
        {:ok, output}
        
      {output, exit_code} ->
        # Failure event
        create_event("tool_call_failed", %{
          tool: "shell_command",
          command: command,
          output: truncate_output(output),
          exit_code: exit_code,
          duration_ms: duration_ms
        }, context)
        
        {:error, {:command_failed, exit_code, output}}
    end
  end
  
  defp create_event(type, data, context) do
    metadata = Map.merge(data, %{
      agent_id: context[:agent_id],
      room_id: context[:room_id],
      tool: "shell_command"
    })
    
    case Event.create(%{
      timestamp: DateTime.utc_now(),
      event_type: type,
      source_id: context[:agent_id] || "shell_tool",
      source_path: "ash_chat/tools/shell",
      content: data[:command] || "",
      description: describe_event(type, data),
      metadata: metadata
    }) do
      {:ok, event} ->
        Logger.info("Created event #{type} for command: #{data[:command]}")
        {:ok, event}
        
      {:error, error} ->
        Logger.error("Failed to create event: #{inspect(error)}")
        {:error, error}
    end
  end
  
  defp describe_event("tool_call_started", data) do
    "Started shell command: #{data[:command]}"
  end
  
  defp describe_event("tool_call_completed", data) do
    "Completed shell command: #{data[:command]} (exit code: #{data[:exit_code]})"
  end
  
  defp describe_event("tool_call_failed", data) do
    "Failed shell command: #{data[:command]} (exit code: #{data[:exit_code]})"
  end
  
  defp describe_event("tool_call_denied", data) do
    "Denied shell command: #{data[:command]} (reason: #{data[:reason]})"
  end
  
  defp describe_event(type, _data) do
    "Shell tool event: #{type}"
  end
  
  defp truncate_output(output) when byte_size(output) > 1000 do
    String.slice(output, 0, 1000) <> "\n... (truncated)"
  end
  defp truncate_output(output), do: output
end