defmodule AshChat.AI.ChatAgent do
  @moduledoc """
  AI Chat Agent for multi-modal conversations using AshAI
  """

  alias LangChain.Chains.LLMChain
  alias LangChain.Message, as: LangChainMessage
  alias AshChat.Resources.{Chat, Message}
  alias AshChat.Tools
  alias AshChat.AI.InferenceConfig

  def create_chat() do
    Chat.create!(%{title: "New Multimodal Chat"})
  end

  def send_text_message(chat_id, content, role \\ :user) do
    Message.create_text_message!(%{
      chat_id: chat_id,
      content: content,
      role: role
    })
  end

  def send_image_message(chat_id, content, image_url, role \\ :user) do
    # For now, we'll store the image URL. Later we can add image processing
    Message.create_image_message!(%{
      chat_id: chat_id,
      content: content,
      image_url: image_url,
      role: role
    })
  end

  def get_chat_messages(chat_id) do
    Message.for_chat!(%{chat_id: chat_id})
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

  def process_message_with_system_prompt(chat_id, message_content, config \\ %{}) do
    require Logger
    
    try do
      # Create user message
      _user_message = send_text_message(chat_id, message_content, :user)
      
      # Get conversation history
      messages = get_chat_messages(chat_id)
      Logger.info("Retrieved #{length(messages)} messages for chat #{chat_id}")
      
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
          ai_message = send_text_message(chat_id, content, :assistant)
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

  def process_multimodal_message(chat_id, message_content, image_url \\ nil, inference_config \\ %{}) do
    # Create user message
    _user_message = if image_url do
      send_image_message(chat_id, message_content, image_url, :user)
    else
      send_text_message(chat_id, message_content, :user)
    end

    # Get conversation history
    messages = get_chat_messages(chat_id)
    
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
          
          # Create AI response message
          ai_message = send_text_message(chat_id, content, :assistant)
          
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
end