defmodule AshChat.Tools.McpClient do
  @moduledoc """
  Client for communicating with Python MCP servers.
  Handles JSON-RPC protocol over stdin/stdout.
  """
  
  require Logger
  alias AshChat.Resources.Event
  
  @doc """
  Execute an MCP method on a Python server
  """
  def call_mcp_server(server_path, method, params \\ %{}, context \\ %{}) do
    request_id = System.unique_integer([:positive])
    
    request = %{
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: request_id
    }
    
    # Create start event
    create_tool_event("tool_call_started", %{
      tool: "mcp_#{Path.basename(server_path, ".py")}",
      method: method,
      params: params,
      server: server_path
    }, context)
    
    start_time = System.monotonic_time(:millisecond)
    
    # Run the Python MCP server
    result = System.cmd("python3", [server_path], 
      input: Jason.encode!(request) <> "\n",
      stderr_to_stdout: false
    )
    
    duration_ms = System.monotonic_time(:millisecond) - start_time
    
    case result do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"result" => result}} ->
            # Success event
            create_tool_event("tool_call_completed", %{
              tool: "mcp_#{Path.basename(server_path, ".py")}",
              method: method,
              params: params,
              result: result,
              duration_ms: duration_ms
            }, context)
            
            {:ok, result}
            
          {:ok, %{"error" => error}} ->
            # MCP error
            create_tool_event("tool_call_failed", %{
              tool: "mcp_#{Path.basename(server_path, ".py")}",
              method: method,
              params: params,
              error: error,
              duration_ms: duration_ms
            }, context)
            
            {:error, {:mcp_error, error}}
            
          {:error, _} ->
            {:error, {:invalid_response, output}}
        end
        
      {output, exit_code} ->
        # Process error
        create_tool_event("tool_call_failed", %{
          tool: "mcp_#{Path.basename(server_path, ".py")}",
          method: method,
          params: params,
          error: output,
          exit_code: exit_code,
          duration_ms: duration_ms
        }, context)
        
        {:error, {:process_failed, exit_code, output}}
    end
  end
  
  @doc """
  Take a screenshot using the screenshot MCP server
  """
  def take_screenshot(source \\ "camera", output_path \\ nil, context \\ %{}) do
    server_path = "/Users/j/Code/athena/system/athena-mcp/screenshot_mcp_server.py"
    
    # First list available cameras
    case call_mcp_server(server_path, "list_screenshot_cameras", %{}, context) do
      {:ok, %{"cameras" => cameras}} when length(cameras) > 0 ->
        # Use first available camera
        camera = hd(cameras)
        camera_id = camera["id"]
        
        params = %{
          camera_id: camera_id,
          output_path: output_path || generate_screenshot_path()
        }
        
        call_mcp_server(server_path, "take_screenshot", params, context)
        
      {:ok, _} ->
        {:error, :no_cameras_available}
        
      error ->
        error
    end
  end
  
  defp generate_screenshot_path do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    "/tmp/screenshot_#{timestamp}.png"
  end
  
  defp create_tool_event(type, data, context) do
    metadata = Map.merge(data, %{
      agent_id: context[:agent_id],
      room_id: context[:room_id]
    })
    
    Event.create(%{
      timestamp: DateTime.utc_now(),
      event_type: type,
      source_id: context[:agent_id] || "mcp_client",
      source_path: "ash_chat/tools/mcp_client",
      content: data[:method] || "",
      description: describe_mcp_event(type, data),
      metadata: metadata
    })
  end
  
  defp describe_mcp_event("tool_call_started", data) do
    "Started MCP call: #{data.method} on #{Path.basename(data.server)}"
  end
  
  defp describe_mcp_event("tool_call_completed", data) do
    "Completed MCP call: #{data.method} (#{data.duration_ms}ms)"
  end
  
  defp describe_mcp_event("tool_call_failed", data) do
    "Failed MCP call: #{data.method} - #{inspect(data[:error])}"
  end
  
  defp describe_mcp_event(type, _data) do
    "MCP event: #{type}"
  end
end