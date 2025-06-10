defmodule AshChat.AI.ChatAgent do
  @moduledoc """
  AI Chat Agent for multi-modal conversations using AshAI
  """

  alias LangChain.Chains.LLMChain
  alias LangChain.Message, as: LangChainMessage
  alias AshChat.Resources.{Room, Message, Profile}
  alias AshChat.Tools
  alias AshChat.AI.InferenceConfig
  alias AshChat.ContextManager

  def create_room() do
    Room.create!(%{title: "New Multimodal Room"})
  end

  def send_text_message(room_id, content, user_id, role \\ :user) do
    # Validate user has membership in room
    validate_room_membership!(room_id, user_id)
    
    Message.create_text_message!(%{
      room_id: room_id,
      content: content,
      role: role,
      user_id: user_id
    })
  end

  def send_image_message(room_id, content, image_url, user_id, role \\ :user) do
    # Validate user has membership in room
    validate_room_membership!(room_id, user_id)
    
    # For now, we'll store the image URL. Later we can add image processing
    Message.create_image_message!(%{
      room_id: room_id,
      content: content,
      image_url: image_url,
      role: role,
      user_id: user_id
    })
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

  def process_message_with_agent_card(room, message_content, agent_card, context_opts \\ []) do
    require Logger
    
    # Build context using the Context Manager
    context_messages = ContextManager.build_context(room, agent_card, context_opts)
    
    # Add the new user message
    user_message = LangChainMessage.new_user!(message_content)
    all_messages = context_messages ++ [user_message]
    
    # Create agent with agent card settings
    agent = create_ai_agent_with_agent_card(room, agent_card, context_opts)
    
    try do
      case LLMChain.run(agent, all_messages) do
        {:ok, updated_chain} ->
          # Get the assistant's response
          [assistant_response | _] = updated_chain.messages
          
          # Store both user and assistant messages  
          # Note: User message handled by caller, only store assistant response
          Message.create_text_message!(%{
            room_id: room.id,
            content: assistant_response.content,
            role: :assistant
          })
          
          {:ok, assistant_response.content}
          
        {:error, reason} ->
          Logger.error("LLM chain execution failed: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
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
      
      result = case Task.yield(task, 10_000) || Task.shutdown(task) do
        {:ok, result} ->
          Logger.info("LLMChain.run returned: #{inspect(result)}")
          result
          
        nil ->
          Logger.error("LLMChain.run timed out after 10 seconds")
          {:error, "Request to Ollama timed out after 10 seconds"}
      end
      
      case result do
        {:ok, %LLMChain{last_message: %{content: content}}} when is_binary(content) ->
          Logger.info("Successfully extracted content from Ollama: #{content}")
          # Create AI response message
          ai_message = Message.create_text_message!(%{
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
          ai_message = Message.create_text_message!(%{
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

  defp get_profile_for_agent_card(agent_card) do
    case agent_card.default_profile_id do
      nil ->
        # Use default profile
        case AshChat.Setup.get_default_profile() do
          {:ok, profile} -> profile
          _ -> 
            # Fallback to first available profile
            case Profile.read() do
              {:ok, [profile | _]} -> profile
              _ -> raise "No profiles available"
            end
        end
      profile_id ->
        case Profile.get(profile_id) do
          {:ok, profile} -> profile
          _ -> get_profile_for_agent_card(%{agent_card | default_profile_id: nil})
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