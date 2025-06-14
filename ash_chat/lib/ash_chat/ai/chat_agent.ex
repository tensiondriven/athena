defmodule AshChat.AI.ChatAgent do
  @moduledoc """
  AI Chat Agent for multi-modal conversations using AshAI
  """

  alias LangChain.Chains.LLMChain
  alias LangChain.Message, as: LangChainMessage
  alias AshChat.Resources.{Room, Message, Persona}
  alias AshChat.Tools
  alias AshChat.AI.InferenceConfig
  alias AshChat.AI.ContextAssembler

  def create_room() do
    # Create room first
    room = Room.create!(%{
      title: "New Chat Room"
    })
    
    # Auto-add agents that are flagged for new rooms
    add_default_agents_to_room(room)
    
    room
  end
  
  defp add_default_agents_to_room(room) do
    # Get all agents that should be auto-added to new rooms
    case AshChat.Resources.AgentCard.get_auto_join_agents() do
      {:ok, auto_join_agents} ->
        for agent_card <- auto_join_agents do
          AshChat.Resources.AgentMembership.create!(%{
            room_id: room.id,
            agent_card_id: agent_card.id,
            role: "participant",
            auto_respond: true
          })
        end
      
      {:error, _} ->
        # If no auto-join agents exist, create and add a default one
        agent_card = get_or_create_default_agent_card()
        AshChat.Resources.AgentMembership.create!(%{
          room_id: room.id,
          agent_card_id: agent_card.id,
          role: "participant", 
          auto_respond: true
        })
    end
  end
  
  defp get_or_create_default_agent_card() do
    case AshChat.Resources.AgentCard.read() do
      {:ok, []} ->
        # No agent cards exist, create a default one
        {:ok, agent_card} = AshChat.Resources.AgentCard.create(%{
          name: "Maya",
          description: "Thoughtful conversationalist who loves meaningful dialogue",
          # No system_message field - this is handled through system_prompt relationship
          model_preferences: %{
            temperature: 0.7,
            max_tokens: 500
          },
          available_tools: [],
          context_settings: %{
            history_limit: 20,
            include_room_metadata: true
          },
          is_default: true,
          add_to_new_rooms: true
        })
        agent_card
      
      {:ok, agent_cards} ->
        # Use default agent card if available, otherwise use first one
        Enum.find(agent_cards, & &1.is_default) || List.first(agent_cards)
      
      {:error, _} ->
        # Fallback: create a simple default
        {:ok, agent_card} = AshChat.Resources.AgentCard.create(%{
          name: "Maya",
          description: "Thoughtful conversationalist who loves meaningful dialogue", 
          # No system_message field - this is handled through system_prompt relationship
          is_default: true,
          add_to_new_rooms: true
        })
        agent_card
    end
  end

  def send_text_message(room_id, content, user_id, role \\ :user) do
    # Validate user has membership in room
    validate_room_membership!(room_id, user_id)
    
    {:ok, message} = Message.create_text_message(%{
      room_id: room_id,
      content: content,
      role: role,
      user_id: user_id
    })
    message
  end

  def send_image_message(room_id, content, image_url, user_id, role \\ :user) do
    # Validate user has membership in room
    validate_room_membership!(room_id, user_id)
    
    # For now, we'll store the image URL. Later we can add image processing
    {:ok, message} = Message.create_image_message(%{
      room_id: room_id,
      content: content,
      image_url: image_url,
      role: role,
      user_id: user_id
    })
    message
  end

  def get_room_messages(room_id) do
    Message.for_room!(%{room_id: room_id})
  end

  def create_ai_agent_with_agent_card(_room, agent_card, _context_opts \\ []) do
    # Get the profile to use (from agent card or default)
    profile = get_profile_for_agent_card(agent_card)
    
    # Merge agent card model preferences with defaults
    inference_params = Map.merge(%{}, agent_card.model_preferences)
    
    chat_model = InferenceConfig.create_chat_model_from_profile(profile, inference_params)
    
    # Filter tools based on agent card's available_tools
    available_tools = filter_tools_for_agent(agent_card.available_tools)
    
    # NOTE: We always use Ollama through remote API at http://10.1.2.200:11434
    # Some Ollama models may not support tool calling, but we still provide them
    # The LLM chain will handle tool calling errors gracefully
    
    %{
      llm: chat_model,
      tools: available_tools,
      verbose: true
    }
    |> LLMChain.new!()
  end

  def create_ai_agent_with_profile(profile, inference_params \\ %{}) do
    chat_model = InferenceConfig.create_chat_model_from_profile(profile, inference_params)
    
    %{
      llm: chat_model,
      tools: Tools.list(),  # Enable AI tool calling
      verbose: true
    }
    |> LLMChain.new!()
  end

  def create_ai_agent(inference_config \\ %{}) do
    config = InferenceConfig.validate_config(inference_config)
    chat_model = InferenceConfig.create_chat_model(config)
    
    %{
      llm: chat_model,
      tools: Tools.list(),  # Enable AI tool calling
      verbose: true
    }
    |> LLMChain.new!()
  end

  def send_message_and_get_ai_response(room_id, user_message_content, user_id, opts \\ []) do
    require Logger
    
    # Get room and agent card
    with {:ok, room} <- Ash.get(Room, room_id),
         {:ok, agent_card} <- get_agent_card_for_room(room) do
      
      # Store user message first
      {:ok, _user_message} = Message.create_text_message(%{
        room_id: room_id,
        content: user_message_content,
        role: :user,
        user_id: user_id
      })
      
      # Build context using the new assembler (conversation history will now include the user message)
      context_opts = build_context_opts_from_agent_card(agent_card, opts || [])
      context_opts_with_user = context_opts ++ [user_id: user_id]
      context_assembler = ContextAssembler.build_for_room(room, agent_card, user_message_content, context_opts_with_user)
      
      # Convert to LangChain messages
      messages = ContextAssembler.assemble(context_assembler)
      
      # Log context inspection for debugging
      Logger.info("Context components: #{inspect(ContextAssembler.inspect_components(context_assembler))}")
      Logger.info("Generated #{length(messages)} messages for LLM")
      
      # Ensure we have at least one message
      if Enum.empty?(messages) do
        Logger.error("No messages generated by context assembler!")
        {:error, "No context messages generated"}
      else
        # Create agent and process
        agent = create_ai_agent_with_agent_card(room, agent_card)
        
        process_with_llm(agent, messages, room_id, agent_card)
      end
    else
      error ->
        Logger.error("Failed to get room or agent card: #{inspect(error)}")
        {:error, "Failed to process message: room or agent card not found"}
    end
  rescue
    error ->
      require Logger
      Logger.error("Exception in automatic AI response: #{Exception.format(:error, error, __STACKTRACE__)}")
      {:error, "Unexpected error: #{Exception.message(error)}"}
  end

  defp process_with_llm(agent, messages, room_id, agent_card) do
    require Logger
    
    case LLMChain.run(agent, messages) do
      {:ok, %LLMChain{last_message: %{content: content}}} when is_binary(content) ->
        # Store AI response with agent metadata
        {:ok, ai_message} = Message.create_text_message(%{
          room_id: room_id,
          content: content,
          role: :assistant,
          metadata: %{
            "agent_name" => if(agent_card, do: agent_card.name, else: "Assistant"),
            "agent_card_id" => if(agent_card, do: agent_card.id, else: nil)
          },
          agent_card_id: if(agent_card, do: agent_card.id, else: nil)
        })
        
        Logger.info("AI response generated and stored for room #{room_id}")
        {:ok, ai_message}
        
      {:error, %LangChain.Chains.LLMChain{}, %LangChain.LangChainError{message: error_msg}} ->
        Logger.error("LLM chain execution failed (3-tuple): #{error_msg}")
        {:error, error_msg}
        
      {:error, _chain, %LangChain.LangChainError{message: error_msg}} ->
        Logger.error("LLM chain execution failed (3-tuple alt): #{error_msg}")
        {:error, error_msg}
        
      {:error, reason} ->
        Logger.error("LLM chain execution failed (2-tuple): #{inspect(reason)}")
        {:error, reason}
        
      other ->
        Logger.error("Unexpected LLMChain.run result: #{inspect(other)}")
        {:error, "Unexpected LLM response format"}
    end
  end

  def process_message_with_agent_card(room, message_content, agent_card, context_opts \\ []) do
    require Logger
    
    # Temporarily disabled - causing broadcast issues
    # TODO: Re-enable after fixing LiveView handle_info
    # # Broadcast "AI is typing" system message
    # typing_message = Message.create_text_message!(%{
    #   room_id: room.id,
    #   content: "#{agent_card.name} is typing...",
    #   role: :system,
    #   metadata: %{
    #     "event_type" => "agent_typing",
    #     "agent_id" => agent_card.id,
    #     "agent_name" => agent_card.name
    #   }
    # })
    # 
    # Phoenix.PubSub.broadcast(
    #   AshChat.PubSub,
    #   "room:#{room.id}",
    #   {:new_message, typing_message}
    # )
    
    # Use the new context assembler
    context_assembler = ContextAssembler.build_for_room(room, agent_card, message_content, context_opts)
    all_messages = ContextAssembler.assemble(context_assembler)
    
    # Create agent with agent card settings
    agent = create_ai_agent_with_agent_card(room, agent_card, context_opts)
    
    # Add messages to the chain before running (like in process_message_with_system_prompt)
    agent_with_messages = Enum.reduce(all_messages, agent, fn msg, chain ->
      LLMChain.add_message(chain, msg)
    end)
    
    # Capture the full request payload
    request_payload = %{
      messages: Enum.map(all_messages, fn msg ->
        %{
          role: to_string(msg.role),
          content: msg.content
        }
      end),
      model: agent.llm.model,
      temperature: Map.get(agent.llm, :temperature, 0.7),
      max_tokens: Map.get(agent.llm, :max_tokens, nil),
      agent_card_id: agent_card.id,
      timestamp: DateTime.utc_now()
    }
    
    # Log the context being sent to LLM for visibility
    Logger.info("=== LLM Request Context for #{agent_card.name} ===")
    Logger.info("Model: #{request_payload.model}")
    Logger.info("Total messages: #{length(all_messages)}")
    
    # Log each message with proper formatting
    Enum.each(all_messages, fn msg ->
      role_label = String.upcase(to_string(msg.role))
      content_preview = String.slice(msg.content, 0, 100)
      content_suffix = if String.length(msg.content) > 100, do: "...", else: ""
      Logger.info("[#{role_label}]: #{content_preview}#{content_suffix}")
    end)
    
    Logger.info("=== End LLM Context ===")
    
    try do
      case LLMChain.run(agent_with_messages) do
        {:ok, updated_chain} ->
          # Get the assistant's response (last message should be the response)
          assistant_response = updated_chain.last_message
          
          # Extract metadata from context_opts if provided
          metadata = context_opts[:metadata] || %{}
          
          # Add full request context to metadata
          enhanced_metadata = Map.merge(metadata, %{
            "request_payload" => request_payload,
            "response_timestamp" => DateTime.utc_now(),
            "agent_name" => agent_card.name,
            "agent_card_id" => agent_card.id
          })
          
          # Store both user and assistant messages  
          # Note: User message handled by caller, only store assistant response
          # Create message using the non-bang version to ensure hooks run
          {:ok, _agent_message} = Message.create_text_message(%{
            room_id: room.id,
            content: assistant_response.content,
            role: :assistant,
            metadata: enhanced_metadata,
            agent_card_id: agent_card.id
          })
          
          # Message event processor will handle broadcasts and agent responses
          {:ok, assistant_response.content}
          
        {:error, _chain, %LangChain.LangChainError{message: error_msg}} ->
          Logger.error("LLM chain execution failed (3-tuple): #{error_msg}")
          {:error, error_msg}
          
        {:error, reason} ->
          Logger.error("LLM chain execution failed: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      # Handle Ollama tool calling errors specifically
      error in FunctionClauseError ->
        if String.contains?(inspect(error), "get_tools_for_api") do
          Logger.warning("Model doesn't support tool calling, retrying without tools")
          # Retry without tools
          agent_without_tools = %{agent_with_messages | tools: []}
          case LLMChain.run(agent_without_tools) do
            {:ok, updated_chain} ->
              assistant_response = updated_chain.last_message
              metadata = context_opts[:metadata] || %{}
              
              # Add full request context to metadata even for retry
              enhanced_metadata = Map.merge(metadata, %{
                "request_payload" => request_payload,
                "response_timestamp" => DateTime.utc_now(),
                "tools_disabled" => true,
                "agent_name" => agent_card.name,
                "agent_card_id" => agent_card.id
              })
              
              # Create message using the non-bang version to ensure hooks run
              {:ok, _agent_message} = Message.create_text_message(%{
                room_id: room.id,
                content: assistant_response.content,
                role: :assistant,
                metadata: enhanced_metadata,
                agent_card_id: agent_card.id
              })
              
              # Message event processor will handle broadcasts and agent responses
              {:ok, assistant_response.content}
              
            {:error, reason} ->
              Logger.error("Retry without tools failed: #{inspect(reason)}")
              {:error, reason}
          end
        else
          Logger.error("Function clause error: #{inspect(error)}")
          {:error, error}
        end
      
      error ->
        Logger.error("Exception in message processing: #{inspect(error)}")
        {:error, error}
    end
  end

  def process_message_with_system_prompt(room_id, message_content, user_id, config \\ %{}) do
    require Logger
    
    try do
      # Create user message
      _user_message = send_text_message(room_id, message_content, user_id, :user)
      
      # Get conversation history
      messages = get_room_messages(room_id)
      Logger.info("Retrieved #{length(messages)} messages for chat #{room_id}")
      
      # Add system prompt as first message if provided
      langchain_messages = if config[:system_prompt] do
        system_msg = %LangChainMessage{role: :system, content: config[:system_prompt]}
        converted = convert_to_langchain_messages(messages)
        Logger.info("Adding system prompt and #{length(converted)} converted messages")
        [system_msg | converted]
      else
        converted = convert_to_langchain_messages(messages)
        Logger.info("No system prompt, using #{length(converted)} converted messages")
        converted
      end
      
      Logger.info("Final langchain_messages count: #{length(langchain_messages)}")
      
      # Process with AI
      agent = create_ai_agent(config)
      
      # Log the configuration for debugging
      Logger.info("Created agent with config: #{inspect(config)}")
      Logger.info("Agent LLM: #{inspect(agent.llm)}")
      
      # Add messages to the chain
      agent_with_messages = Enum.reduce(langchain_messages, agent, fn msg, chain ->
        LLMChain.add_message(chain, msg)
      end)
      
      # Log what we're about to send
      Logger.info("Calling LLMChain.run with #{length(langchain_messages)} messages added to chain")
      
      # Run with a timeout to catch hanging requests
      task = Task.async(fn ->
        LLMChain.run(agent_with_messages)
      end)
      
      result = case Task.yield(task, 60_000) || Task.shutdown(task) do
        {:ok, result} ->
          Logger.info("LLMChain.run returned: #{inspect(result)}")
          result
          
        nil ->
          Logger.error("LLMChain.run timed out after 60 seconds")
          {:error, "Request to Ollama timed out after 60 seconds"}
      end
      
      case result do
        {:ok, %LLMChain{last_message: %{content: content}}} when is_binary(content) ->
          Logger.info("Successfully extracted content from Ollama: #{content}")
          # Create AI response message
          {:ok, ai_message} = Message.create_text_message(%{
            room_id: room_id,
            content: content,
            role: :assistant
          })
          Logger.info("Created AI message: #{inspect(ai_message)}")
          {:ok, ai_message}
          
        {:ok, chain} ->
          # Fallback if structure is different
          Logger.warning("Unexpected chain structure: #{inspect(chain)}")
          {:error, "Received response but couldn't extract content"}
        
        {:error, %{message: "LLMChain cannot be run without messages"}} ->
          Logger.error("LLMChain error - no messages found. Config: #{inspect(config)}, Messages count: #{length(messages)}, LangChain messages: #{inspect(langchain_messages)}")
          {:error, "Cannot process chat without message history. Please ensure at least one message exists."}
          
        {:error, _chain, %LangChain.LangChainError{type: "unexpected_response", message: msg}} ->
          Logger.error("Connection error to Ollama: #{msg}")
          {:error, "Cannot connect to Ollama server. Please ensure Ollama is running and accessible."}
          
        {:error, error} ->
          error_msg = case error do
            %{message: msg} -> msg
            _ -> inspect(error)
          end
          Logger.error("AI processing failed: #{error_msg}")
          {:error, "AI processing failed: #{error_msg}"}
          
        other ->
          Logger.error("Unexpected LLMChain.run result: #{inspect(other)}")
          {:error, "Unexpected response from AI: #{inspect(other)}"}
      end
    rescue
      error in KeyError ->
        Logger.error("Configuration key error: #{inspect(error)}. Config: #{inspect(config)}")
        {:error, "Configuration error: Invalid configuration format. #{Exception.message(error)}"}
        
      error in ArgumentError ->
        Logger.error("Argument error in chat processing: #{inspect(error)}")
        {:error, "Invalid argument: #{Exception.message(error)}"}
        
      error in CaseClauseError ->
        case error.term do
          {:error, _chain, %{message: msg}} ->
            Logger.error("Chat processing case clause error: #{msg}")
            {:error, "Chat processing error: #{msg}"}
          _ ->
            Logger.error("Chat processing error: #{inspect(error)}")
            {:error, "Chat processing error: #{inspect(error)}"}
        end
        
      error ->
        Logger.error("Unexpected error in chat processing: #{Exception.format(:error, error, __STACKTRACE__)}")
        {:error, "Unexpected error: #{Exception.message(error)}"}
    end
  end

  def process_multimodal_message(room_id, message_content, user_id, image_url \\ nil, inference_config \\ %{}) do
    # Create user message
    _user_message = if image_url do
      send_image_message(room_id, message_content, image_url, user_id, :user)
    else
      send_text_message(room_id, message_content, user_id, :user)
    end

    # Get conversation history
    messages = get_room_messages(room_id)
    
    # TODO: Get relevant context using semantic search when vectorization is enabled
    # context_messages = if length(messages) > 5 do
    #   case Message.semantic_search(%{
    #     query: message_content,
    #     limit: 3,
    #     threshold: 0.8
    #   }) do
    #     {:ok, relevant} -> relevant
    #     {:error, _} -> []
    #   end
    # else
    #   []
    # end
    context_messages = []
    
    # Combine recent messages with relevant context
    all_messages = (context_messages ++ messages) |> Enum.uniq_by(& &1.id)
    
    # Convert to LangChain format
    langchain_messages = convert_to_langchain_messages(all_messages)
    
    # Process with AI
    agent = create_ai_agent(inference_config)
    
    try do
      # Run with tool support (streaming handled separately)
      case LLMChain.run(agent, langchain_messages) do
        {:ok, response} ->
          # Handle potential tool calls in response
          content = case response do
            %{content: content} when is_binary(content) -> content
            %{tool_calls: tool_calls} when is_list(tool_calls) ->
              # Handle tool call responses
              tool_results = Enum.map(tool_calls, &format_tool_result/1)
              "Tool calls executed:\n" <> Enum.join(tool_results, "\n")
            _ -> "AI response processed"
          end
          
          # Create AI response message (AI assistant doesn't need user_id validation)
          {:ok, ai_message} = Message.create_text_message(%{
            room_id: room_id,
            content: content,
            role: :assistant
          })
          
          {:ok, ai_message}
        
        {:error, %{message: "LLMChain cannot be run without messages"}} ->
          {:error, "Cannot process chat without message history. Please ensure at least one message exists."}
          
        {:error, error} ->
          error_msg = case error do
            %{message: msg} -> msg
            _ -> inspect(error)
          end
          {:error, "AI processing failed: #{error_msg}"}
      end
    rescue
      error in CaseClauseError ->
        case error.term do
          {:error, _chain, %{message: msg}} ->
            {:error, "Chat processing error: #{msg}"}
          _ ->
            {:error, "Chat processing error: #{inspect(error)}"}
        end
        
      error ->
        error_msg = Exception.message(error)
        {:error, "Unexpected error: #{error_msg}"}
    end
  end

  defp convert_to_langchain_messages(ash_messages) do
    Enum.map(ash_messages, fn msg ->
      case msg.message_type do
        :text ->
          %LangChainMessage{
            role: msg.role,
            content: msg.content
          }
        
        :image ->
          # For multimodal messages with images
          content = if msg.image_url do
            [
              %{type: "text", text: msg.content},
              %{type: "image_url", image_url: %{url: msg.image_url}}
            ]
          else
            msg.content
          end
          
          %LangChainMessage{
            role: msg.role,
            content: content
          }
        
        _ ->
          %LangChainMessage{
            role: msg.role,
            content: msg.content
          }
      end
    end)
  end

  defp format_tool_result(%{name: name, result: result}) do
    "#{name}: #{result}"
  end

  defp format_tool_result(%{function: %{name: name}, result: result}) do
    "#{name}: #{result}"
  end

  defp format_tool_result(tool_call) do
    "Tool executed: #{inspect(tool_call)}"
  end

  # Helper functions for Agent Card system

  defp get_agent_card_for_room(room) do
    # Get the first auto-responding agent for this room
    case AshChat.Resources.AgentMembership.auto_responders_for_room(%{room_id: room.id}) do
      {:ok, [agent_membership | _]} ->
        Ash.get(AshChat.Resources.AgentCard, agent_membership.agent_card_id)
      
      {:ok, []} ->
        {:error, "Room has no auto-responding agents"}
      
      {:error, reason} ->
        {:error, "Failed to get agents for room: #{inspect(reason)}"}
    end
  end

  defp build_context_opts_from_agent_card(agent_card, additional_opts) do
    context_settings = agent_card.context_settings || %{}
    
    [
      history_limit: Map.get(context_settings, "history_limit", 20),
      include_room_metadata: Map.get(context_settings, "include_room_metadata", true),
      include_system_message: true
    ] ++ additional_opts
  end

  defp get_profile_for_agent_card(agent_card) do
    case agent_card.default_persona_id do
      nil ->
        # Use default profile
        case AshChat.Setup.get_default_profile() do
          {:ok, profile} -> profile
          _ -> 
            # Fallback to first available profile
            case Persona.read() do
              {:ok, [profile | _]} -> profile
              _ -> raise "No profiles available"
            end
        end
      profile_id ->
        case Persona.get_by_id(profile_id) do
          {:ok, profile} -> profile
          _ -> get_profile_for_agent_card(%{agent_card | default_persona_id: nil})
        end
    end
  end

  defp filter_tools_for_agent(available_tool_names) do
    all_tools = Tools.list()
    
    if Enum.empty?(available_tool_names) do
      # If no specific tools listed, use all tools
      all_tools
    else
      # Filter tools based on available_tool_names
      Enum.filter(all_tools, fn tool ->
        tool_name = get_tool_name(tool)
        tool_name in available_tool_names
      end)
    end
  end

  defp get_tool_name(tool) do
    # Extract tool name from LangChain tool structure
    case tool do
      %{name: name} -> name
      %{function: %{name: name}} -> name
      _ -> "unknown_tool"
    end
  end

  # Validation functions for user/room integration
  
  defp validate_room_membership!(room_id, user_id) do
    alias AshChat.Resources.RoomMembership
    
    case RoomMembership.for_user_and_room(%{user_id: user_id, room_id: room_id}) do
      {:ok, [_membership | _]} -> 
        :ok
      {:ok, []} -> 
        raise ArgumentError, "User #{user_id} is not a member of room #{room_id}"
      {:error, error} ->
        raise ArgumentError, "Failed to validate room membership: #{inspect(error)}"
    end
  end
end