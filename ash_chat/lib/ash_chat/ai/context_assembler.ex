defmodule AshChat.AI.ContextAssembler do
  @moduledoc """
  Plug-style context assembler for modular AI context composition.
  Each component can be assembled separately and tagged for debugging/inspection.
  """

  alias LangChain.Message, as: LangChainMessage
  alias AshChat.AI.ChatAgent

  defstruct components: [], metadata: %{}

  @type component :: %{
    type: atom(),
    content: any(),
    priority: integer(),
    metadata: map()
  }

  @type t :: %__MODULE__{
    components: [component()],
    metadata: map()
  }

  def new(metadata \\ %{}) do
    %__MODULE__{components: [], metadata: metadata}
  end

  def add_component(%__MODULE__{} = assembler, type, content, opts \\ []) do
    priority = Keyword.get(opts, :priority, 50)
    metadata = Keyword.get(opts, :metadata, %{})
    
    component = %{
      type: type,
      content: content,
      priority: priority,
      metadata: metadata
    }
    
    %{assembler | components: [component | assembler.components]}
  end

  def assemble(%__MODULE__{} = assembler) do
    messages = assembler.components
    |> Enum.sort_by(& &1.priority)
    |> Enum.map(&convert_component_to_message/1)
    |> List.flatten()
    
    # Ensure we always have at least one message
    if Enum.empty?(messages) do
      [%LangChainMessage{role: :system, content: "You are a helpful AI assistant."}]
    else
      messages
    end
  end

  def build_for_room(room, agent_card, user_message_content, opts \\ []) do
    assembler = new(%{room_id: room.id, agent_card_id: agent_card.id})
    
    assembler
    |> maybe_add_system_message(agent_card, opts)
    |> maybe_add_room_context(room, opts)
    |> maybe_add_conversation_history(room, opts)
    |> add_user_message(user_message_content, opts)
  end

  defp maybe_add_system_message(assembler, agent_card, opts) do
    if Keyword.get(opts, :include_system_message, true) do
      system_content = agent_card.system_message || "You are a helpful AI assistant."
      
      add_component(assembler, :system_message, system_content,
        priority: 10,
        metadata: %{agent_card: agent_card.name, source: "agent_card"}
      )
    else
      assembler
    end
  end

  defp maybe_add_room_context(assembler, room, opts) do
    if Keyword.get(opts, :include_room_metadata, true) do
      room_context = %{
        room_title: room.title,
        room_id: room.id,
        created_at: room.created_at
      }
      
      add_component(assembler, :room_context, room_context,
        priority: 20,
        metadata: %{room_id: room.id, source: "room_metadata"}
      )
    else
      assembler
    end
  end

  defp maybe_add_conversation_history(assembler, room, opts) do
    history_limit = Keyword.get(opts, :history_limit, 20)
    
    if history_limit > 0 do
      messages = ChatAgent.get_room_messages(room.id)
      recent_messages = Enum.take(messages, -history_limit)
      
      add_component(assembler, :conversation_history, recent_messages,
        priority: 30,
        metadata: %{
          message_count: length(recent_messages),
          history_limit: history_limit,
          source: "conversation_history"
        }
      )
    else
      assembler
    end
  end

  defp add_user_message(assembler, content, opts) do
    user_id = Keyword.get(opts, :user_id)
    
    add_component(assembler, :user_message, content,
      priority: 40,
      metadata: %{user_id: user_id, source: "current_input"}
    )
  end

  defp convert_component_to_message(%{type: :system_message, content: content}) do
    %LangChainMessage{role: :system, content: content}
  end

  defp convert_component_to_message(%{type: :room_context, content: context}) do
    context_text = """
    Room: #{context.room_title}
    Created: #{Calendar.strftime(context.created_at, "%B %d, %Y at %I:%M %p")}
    """
    
    %LangChainMessage{role: :system, content: "Context: " <> String.trim(context_text)}
  end

  defp convert_component_to_message(%{type: :conversation_history, content: messages}) do
    require Logger
    Logger.info("Converting #{length(messages)} conversation history messages")
    
    Enum.map(messages, fn msg ->
      case msg.message_type do
        :text ->
          %LangChainMessage{
            role: msg.role,
            content: msg.content
          }
        
        :image ->
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

  defp convert_component_to_message(%{type: :user_message, content: content}) do
    %LangChainMessage{role: :user, content: content}
  end

  defp convert_component_to_message(%{type: _unknown, content: content}) when is_binary(content) do
    %LangChainMessage{role: :system, content: content}
  end

  defp convert_component_to_message(_component) do
    []
  end

  def inspect_components(%__MODULE__{} = assembler) do
    assembler.components
    |> Enum.sort_by(& &1.priority)
    |> Enum.with_index()
    |> Enum.map(fn {component, index} ->
      %{
        order: index + 1,
        type: component.type,
        priority: component.priority,
        content_preview: preview_content(component.content),
        metadata: component.metadata
      }
    end)
  end

  defp preview_content(content) when is_binary(content) do
    if String.length(content) > 100 do
      String.slice(content, 0, 97) <> "..."
    else
      content
    end
  end

  defp preview_content(content) when is_list(content) do
    "#{length(content)} items"
  end

  defp preview_content(content) when is_map(content) do
    keys = Map.keys(content)
    "Map with keys: #{inspect(keys)}"
  end

  defp preview_content(content) do
    inspect(content)
  end
end