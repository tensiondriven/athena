defmodule AshChat.Resources.PromptTemplate do
  @moduledoc """
  PromptTemplate handles model-specific prompt formatting.
  
  Separates character data (in Character) from model-specific formatting
  requirements. Supports different models like Qwen, Llama, Mistral with
  their specific chat templates, special tokens, and formatting rules.
  """
  
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      description "Template name (e.g., 'ChatML', 'Alpaca', 'Llama3')"
    end

    attribute :model_family, :string do
      allow_nil? false
      description "Model family this template supports (e.g., 'qwen', 'llama3', 'mistral')"
    end

    attribute :description, :string do
      description "Description of when to use this template"
    end

    # Chat formatting template
    attribute :system_template, :string do
      description "Template for system messages with {{content}} placeholder"
    end

    attribute :user_template, :string do
      description "Template for user messages with {{content}} placeholder"
    end

    attribute :assistant_template, :string do
      description "Template for assistant messages with {{content}} placeholder"
    end

    attribute :conversation_starter, :string do
      description "How to start a conversation (e.g., chat start tokens)"
    end

    attribute :conversation_ender, :string do
      description "How to end a conversation (e.g., EOS tokens)"
    end

    # Special tokens and formatting
    attribute :special_tokens, :map do
      default %{}
      description "Special tokens map (e.g., %{'bos' => '<|im_start|>', 'eos' => '<|im_end|>'})"
    end

    attribute :stop_sequences, {:array, :string} do
      default []
      description "Stop sequences for this model format"
    end

    # Template configuration
    attribute :requires_system_message, :boolean do
      default true
      description "Whether this template requires a system message"
    end

    attribute :supports_multi_turn, :boolean do
      default true
      description "Whether this template supports multi-turn conversations"
    end

    attribute :max_context_tokens, :integer do
      description "Recommended max context length for this template"
    end

    # Metadata
    attribute :is_active, :boolean do
      default true
      description "Whether this template is available for use"
    end

    attribute :is_default_for_family, :boolean do
      default false
      description "Whether this is the default template for the model family"
    end

    timestamps()
  end

  relationships do
    # Note: Profile-PromptTemplate relationship not yet implemented
    # has_many :profiles, AshChat.Resources.Profile do
    #   description "Profiles configured to use this template"
    # end
  end

  actions do
    defaults [:read, :destroy]
    
    create :create do
      accept [:name, :model_family, :description, :system_template, :user_template,
              :assistant_template, :conversation_starter, :conversation_ender,
              :special_tokens, :stop_sequences, :requires_system_message,
              :supports_multi_turn, :max_context_tokens, :is_active, :is_default_for_family]
    end
    
    update :update do
      accept [:name, :model_family, :description, :system_template, :user_template,
              :assistant_template, :conversation_starter, :conversation_ender,
              :special_tokens, :stop_sequences, :requires_system_message,
              :supports_multi_turn, :max_context_tokens, :is_active, :is_default_for_family]
    end
    
    read :active do
      filter expr(is_active == true)
    end

    read :for_model_family do
      argument :model_family, :string, allow_nil?: false
      filter expr(model_family == ^arg(:model_family) and is_active == true)
    end

    read :default_for_family do
      argument :model_family, :string, allow_nil?: false
      filter expr(model_family == ^arg(:model_family) and is_default_for_family == true)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :update
    define :destroy
    define :active
    define :for_model_family, args: [:model_family]
    define :default_for_family, args: [:model_family]
  end

  # Prompt formatting functions
  def format_system_message(template, content) do
    apply_template(template.system_template, content, template.special_tokens)
  end

  def format_user_message(template, content) do
    apply_template(template.user_template, content, template.special_tokens)
  end

  def format_assistant_message(template, content) do
    apply_template(template.assistant_template, content, template.special_tokens)
  end

  def format_conversation(template, messages) do
    formatted_messages = Enum.map(messages, fn msg ->
      case msg.role do
        :system -> format_system_message(template, msg.content)
        :user -> format_user_message(template, msg.content)
        :assistant -> format_assistant_message(template, msg.content)
      end
    end)

    conversation = Enum.join(formatted_messages, "")
    
    template.conversation_starter <> conversation <> template.conversation_ender
  end

  defp apply_template(nil, content, _tokens), do: content
  defp apply_template(template, content, tokens) do
    # Replace {{content}} placeholder
    result = String.replace(template, "{{content}}", content)
    
    # Replace special token placeholders like {{bos}}, {{eos}}
    Enum.reduce(tokens, result, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", value)
    end)
  end

  # SillyTavern template compatibility helpers
  def to_sillytavern_format(template) do
    %{
      "name" => template.name,
      "system_sequence" => template.system_template,
      "user_sequence" => template.user_template,
      "assistant_sequence" => template.assistant_template,
      "stop_sequence" => template.stop_sequences,
      "wrap" => template.supports_multi_turn,
      "macro" => true
    }
  end
end