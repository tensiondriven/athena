defmodule AshChat.Tools do
  @moduledoc """
  AI Tools for chat agents - integrated with LangChain
  """
  
  alias AshChat.Tools.{Shell, McpClient}
  alias AshChat.Resources.{Event, Message}
  
  @doc """
  List all available tools for LangChain integration
  """
  def list() do
    [
      shell_command_tool(),
      get_recent_events_tool(),
      take_screenshot_tool(),
      search_messages_tool(),
      create_room_tool()
    ]
  end
  
  # Tool Definitions
  
  defp shell_command_tool() do
    %{
      name: "shell_command",
      description: "Execute a whitelisted shell command. Available commands: #{Enum.join(Shell.whitelisted_commands(), ", ")}",
      parameters: %{
        type: "object",
        properties: %{
          command: %{
            type: "string",
            description: "The shell command to execute (must be whitelisted)"
          }
        },
        required: ["command"]
      },
      function: fn %{"command" => command}, context ->
        case Shell.execute(command, context) do
          {:ok, output} ->
            %{success: true, output: output}
          {:error, {:not_whitelisted, allowed}} ->
            %{
              success: false, 
              error: "Command not whitelisted. Allowed: #{Enum.join(allowed, ", ")}",
              retry_hint: "Try using one of the allowed commands"
            }
          {:error, reason} ->
            %{success: false, error: inspect(reason)}
        end
      end
    }
  end
  
  defp get_recent_events_tool() do
    %{
      name: "get_recent_events",
      description: "Get recent events from the system, optionally filtered by type",
      parameters: %{
        type: "object",
        properties: %{
          limit: %{
            type: "integer",
            description: "Number of events to return (default: 20, max: 100)"
          },
          event_type: %{
            type: "string",
            description: "Optional: filter by event type (e.g., 'tool_call_completed', 'message_created')"
          }
        }
      },
      function: fn params, _context ->
        limit = min(params["limit"] || 20, 100)
        
        result = if event_type = params["event_type"] do
          Event.by_event_type(%{event_type: event_type, limit: limit})
        else
          Event.recent(%{limit: limit})
        end
        
        case result do
          {:ok, events} ->
            %{
              success: true,
              count: length(events),
              events: Enum.map(events, &format_event/1)
            }
          {:error, error} ->
            %{success: false, error: inspect(error)}
        end
      end
    }
  end
  
  defp take_screenshot_tool() do
    %{
      name: "take_screenshot",
      description: "Take a screenshot using available camera/screen capture",
      parameters: %{
        type: "object",
        properties: %{
          source: %{
            type: "string",
            description: "Screenshot source: 'screen' for desktop or 'camera' for webcam",
            enum: ["screen", "camera"]
          },
          save_to_message: %{
            type: "boolean",
            description: "Whether to save the screenshot as a message attachment"
          }
        },
        required: ["source"]
      },
      function: fn params, context ->
        source = params["source"] || "camera"
        
        case McpClient.take_screenshot(source, nil, context) do
          {:ok, result} ->
            # Store screenshot data if requested
            if params["save_to_message"] && result["success"] do
              # TODO: Create message with image attachment
              # For now, just return the result
            end
            
            %{
              success: result["success"],
              filename: result["output_path"],
              camera_info: result["camera"],
              message: "Screenshot taken successfully"
            }
            
          {:error, :no_cameras_available} ->
            %{
              success: false,
              error: "No cameras available for screenshots"
            }
            
          {:error, reason} ->
            %{
              success: false,
              error: "Screenshot failed: #{inspect(reason)}"
            }
        end
      end
    }
  end
  
  defp search_messages_tool() do
    %{
      name: "search_messages",
      description: "Search for messages in the current room",
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Search query"
          },
          limit: %{
            type: "integer",
            description: "Maximum number of results (default: 5)"
          }
        },
        required: ["query"]
      },
      function: fn params, context ->
        # Simple text search for now
        limit = params["limit"] || 5
        query = String.downcase(params["query"])
        
        case Message.for_room(%{room_id: context[:room_id]}) do
          {:ok, messages} ->
            matching = messages
            |> Enum.filter(fn msg -> 
              String.downcase(msg.content) |> String.contains?(query)
            end)
            |> Enum.take(limit)
            
            %{
              success: true,
              count: length(matching),
              messages: Enum.map(matching, fn msg ->
                %{
                  id: msg.id,
                  content: msg.content,
                  role: msg.role,
                  created_at: msg.created_at
                }
              end)
            }
            
          {:error, error} ->
            %{success: false, error: inspect(error)}
        end
      end
    }
  end
  
  defp create_room_tool() do
    %{
      name: "create_room",
      description: "Create a new chat room",
      parameters: %{
        type: "object",
        properties: %{
          title: %{
            type: "string",
            description: "Title for the new room"
          }
        },
        required: ["title"]
      },
      function: fn %{"title" => title}, _context ->
        case AshChat.Resources.Room.create(%{title: title}) do
          {:ok, room} ->
            %{
              success: true,
              room_id: room.id,
              title: room.title,
              message: "Created new room '#{room.title}'"
            }
          {:error, error} ->
            %{success: false, error: inspect(error)}
        end
      end
    }
  end
  
  # Helper functions
  
  defp format_event(event) do
    %{
      id: event.id,
      type: event.event_type,
      timestamp: event.timestamp,
      description: event.description,
      metadata: event.metadata
    }
  end
end