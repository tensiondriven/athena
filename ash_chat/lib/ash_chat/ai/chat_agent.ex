defmodule AshChat.AI.ChatAgent do
  @moduledoc """
  AI Chat Agent for multi-modal conversations using AshAI
  """

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Messages.Message, as: LangChainMessage
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
    # Create user message
    _user_message = send_text_message(chat_id, message_content, :user)
    
    # Get conversation history
    messages = get_chat_messages(chat_id)
    
    # Add system prompt as first message if provided
    langchain_messages = if config[:system_prompt] do
      [%LangChainMessage{role: :system, content: config.system_prompt} | convert_to_langchain_messages(messages)]
    else
      convert_to_langchain_messages(messages)
    end
    
    # Process with AI
    agent = create_ai_agent(config)
    
    try do
      case LLMChain.run(agent, langchain_messages) do
        {:ok, response} ->
          content = case response do
            %{content: content} when is_binary(content) -> content
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
      %CaseClauseError{term: {:error, _chain, %{message: msg}}} ->
        {:error, "Chat processing error: #{msg}"}
        
      error ->
        error_msg = Exception.message(error)
        {:error, "Unexpected error: #{error_msg}"}
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
      %CaseClauseError{term: {:error, _chain, %{message: msg}}} ->
        {:error, "Chat processing error: #{msg}"}
        
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