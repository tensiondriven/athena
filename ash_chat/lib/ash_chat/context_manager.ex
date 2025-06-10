defmodule AshChat.ContextManager do
  @moduledoc """
  Plug-like context manager for assembling conversation context from multiple sources.
  
  Builds conversation context by combining:
  - Agent card system message and settings
  - Conversation history (with limits)
  - Relevant context (via vector search)
  - Room metadata and parentage
  """

  alias AshChat.Resources.{Room, Message, AgentCard}
  alias LangChain.Message, as: LangChainMessage

  @type context_options :: [
    history_limit: non_neg_integer(),
    vector_search: boolean(),
    include_room_metadata: boolean(),
    include_parent_context: boolean()
  ]

  @doc """
  Build complete conversation context for an agent in a room.
  
  ## Examples
  
      context = ContextManager.build_context(room, agent_card)
      context = ContextManager.build_context(room, agent_card, history_limit: 20)
  """
  @spec build_context(Room.t(), AgentCard.t(), context_options()) :: [LangChainMessage.t()]
  def build_context(room, agent_card, opts \\ []) do
    opts = Keyword.merge(default_options(agent_card), opts)
    
    []
    |> add_system_message(agent_card)
    |> add_parent_context(room, opts)
    |> add_room_metadata(room, opts)
    |> add_conversation_history(room, opts)
    |> add_relevant_context(room, agent_card, opts)
  end

  @doc """
  Add a context component to the message list.
  Follows a plug-like pattern where each function takes and returns the context list.
  """
  def add_system_message(context, agent_card) do
    system_msg = LangChainMessage.new_system!(agent_card.system_message)
    [system_msg | context]
  end

  def add_parent_context(context, room, opts) do
    if opts[:include_parent_context] && room.parent_room_id do
      case Room.get(room.parent_room_id) do
        {:ok, parent_room} ->
          parent_summary = summarize_room_context(parent_room)
          context_msg = LangChainMessage.new_system!("""
          Parent conversation context: #{parent_summary}
          """)
          context ++ [context_msg]
        _ -> 
          context
      end
    else
      context
    end
  end

  def add_room_metadata(context, room, opts) do
    if opts[:include_room_metadata] do
      metadata_msg = LangChainMessage.new_system!("""
      Room: #{room.title}
      Created: #{room.created_at}
      """)
      context ++ [metadata_msg]
    else
      context
    end
  end

  def add_conversation_history(context, room, opts) do
    limit = opts[:history_limit] || 50
    
    case Message.for_room(room.id) do
      {:ok, messages} ->
        history_messages = 
          messages
          |> Enum.take(-limit)  # Take last N messages
          |> Enum.map(&convert_to_langchain_message/1)
        
        context ++ history_messages
      _ ->
        context
    end
  end

  def add_relevant_context(context, _room, _agent_card, opts) do
    if opts[:vector_search] do
      # TODO: Implement vector search for relevant context
      # This would search vectorized conversation history for relevant snippets
      context
    else
      context
    end
  end

  # Private functions

  defp default_options(agent_card) do
    agent_card.context_settings
    |> Map.merge(%{
      history_limit: 50,
      vector_search: false,
      include_room_metadata: true,
      include_parent_context: true
    })
    |> Enum.into([])
  end

  defp convert_to_langchain_message(message) do
    role = case message.role do
      :user -> :user
      :assistant -> :assistant
      :system -> :system
    end
    
    case message.message_type do
      :text -> 
        %LangChainMessage{role: role, content: message.content}
      :image ->
        # TODO: Handle multimodal messages
        %LangChainMessage{role: role, content: message.content}
      :multimodal ->
        # TODO: Handle complex multimodal content
        %LangChainMessage{role: role, content: message.content}
    end
  end

  defp summarize_room_context(room) do
    # TODO: Use LLM to summarize parent room context
    "Previous conversation in room: #{room.title}"
  end
end