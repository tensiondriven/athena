defmodule AshChatWeb.PromptVisualizerLive do
  @moduledoc """
  LiveView for visualizing prompt template formatting and generation.
  
  Shows how different prompt parts (system, user, assistant, special tokens)
  combine into the final prompt for different model templates.
  """
  
  use AshChatWeb, :live_view
  
  alias AshChat.Resources.{PromptTemplate, Character}

  def mount(_params, _session, socket) do
    try do
      templates = PromptTemplate.active!() || []
      characters = Character.active!() || []
      
      socket = 
        socket
        |> assign(:templates, templates)
        |> assign(:characters, characters)
        |> assign(:selected_template, List.first(templates))
        |> assign(:selected_character, List.first(characters))
        |> assign(:sample_messages, default_sample_messages())
        |> assign(:custom_system, "")
        |> assign(:custom_user, "")
        |> assign(:show_tokens, true)
        |> assign(:show_formatting, true)
        |> update_preview()
        
      {:ok, socket}
    rescue
      error ->
        IO.puts("Error in PromptVisualizerLive mount: #{inspect(error)}")
        socket = 
          socket
          |> assign(:templates, [])
          |> assign(:characters, [])
          |> assign(:selected_template, nil)
          |> assign(:selected_character, nil)
          |> assign(:sample_messages, default_sample_messages())
          |> assign(:custom_system, "")
          |> assign(:custom_user, "")
          |> assign(:show_tokens, true)
          |> assign(:show_formatting, true)
          |> assign(:formatted_prompt, "No templates available")
          |> assign(:message_parts, [])
          |> assign(:conversation_messages, [])
        
        {:ok, socket}
    end
  end
  
  def handle_event("select_template", %{"template_id" => template_id}, socket) do
    template = Enum.find(socket.assigns.templates, &(&1.id == template_id))
    
    socket = 
      socket
      |> assign(:selected_template, template)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    character = Enum.find(socket.assigns.characters, &(&1.id == character_id))
    
    socket = 
      socket
      |> assign(:selected_character, character)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("update_custom_system", %{"value" => value}, socket) do
    socket = 
      socket
      |> assign(:custom_system, value)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("update_custom_user", %{"value" => value}, socket) do
    socket = 
      socket
      |> assign(:custom_user, value)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("toggle_tokens", _params, socket) do
    socket = 
      socket
      |> assign(:show_tokens, !socket.assigns.show_tokens)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("toggle_formatting", _params, socket) do
    socket = 
      socket
      |> assign(:show_formatting, !socket.assigns.show_formatting)
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("use_sample_conversation", _params, socket) do
    socket = 
      socket
      |> assign(:sample_messages, sample_conversation())
      |> update_preview()
    
    {:noreply, socket}
  end
  
  def handle_event("reset_to_default", _params, socket) do
    socket = 
      socket
      |> assign(:sample_messages, default_sample_messages())
      |> assign(:custom_system, "")
      |> assign(:custom_user, "")
      |> update_preview()
    
    {:noreply, socket}
  end
  
  defp update_preview(socket) do
    template = socket.assigns.selected_template
    character = socket.assigns.selected_character
    custom_system = socket.assigns.custom_system
    custom_user = socket.assigns.custom_user
    messages = socket.assigns.sample_messages
    
    # Build system message from character or custom input
    system_content = if String.trim(custom_system) != "" do
      custom_system
    else
      build_character_system_prompt(character)
    end
    
    # Build conversation messages
    conversation_messages = [
      %{role: :system, content: system_content}
      | messages
    ]
    
    # Add custom user message if provided
    conversation_messages = if String.trim(custom_user) != "" do
      conversation_messages ++ [%{role: :user, content: custom_user}]
    else
      conversation_messages
    end
    
    # Generate the formatted prompt
    {formatted_prompt, message_parts} = if template do
      formatted = PromptTemplate.format_conversation(template, conversation_messages)
      parts = build_message_parts(template, conversation_messages)
      {formatted, parts}
    else
      {"No template selected", []}
    end
    
    socket
    |> assign(:formatted_prompt, formatted_prompt)
    |> assign(:message_parts, message_parts)
    |> assign(:conversation_messages, conversation_messages)
  end
  
  defp build_character_system_prompt(nil), do: nil
  defp build_character_system_prompt(character) do
    base = "You are #{character.name}."
    
    parts = [
      (if character.description, do: character.description),
      (if character.personality, do: "Personality: #{character.personality}"),
      (if character.scenario, do: "Scenario: #{character.scenario}")
    ]
    |> Enum.filter(& &1)
    
    if Enum.any?(parts) do
      base <> "\n\n" <> Enum.join(parts, "\n\n")
    else
      base
    end
  end
  
  defp build_message_parts(template, messages) do
    Enum.map(messages, fn msg ->
      formatted = case msg.role do
        :system -> PromptTemplate.format_system_message(template, msg.content)
        :user -> PromptTemplate.format_user_message(template, msg.content)
        :assistant -> PromptTemplate.format_assistant_message(template, msg.content)
      end
      
      %{
        role: msg.role,
        content: msg.content,
        formatted: formatted,
        template_used: get_template_for_role(template, msg.role)
      }
    end)
  end
  
  defp get_template_for_role(template, :system), do: template.system_template
  defp get_template_for_role(template, :user), do: template.user_template
  defp get_template_for_role(template, :assistant), do: template.assistant_template
  
  defp default_sample_messages do
    [
      %{role: :user, content: "Hello! How are you today?"},
      %{role: :assistant, content: "I'm doing well, thank you for asking! How can I help you today?"}
    ]
  end
  
  defp sample_conversation do
    [
      %{role: :user, content: "Can you help me write a Python function?"},
      %{role: :assistant, content: "Of course! I'd be happy to help you write a Python function. What would you like the function to do?"},
      %{role: :user, content: "I need a function that calculates the factorial of a number."},
      %{role: :assistant, content: "Here's a Python function that calculates the factorial of a number:\n\n```python\ndef factorial(n):\n    if n < 0:\n        raise ValueError(\"Factorial is not defined for negative numbers\")\n    elif n == 0 or n == 1:\n        return 1\n    else:\n        return n * factorial(n - 1)\n```\n\nThis function uses recursion and includes error handling for negative numbers."}
    ]
  end
  
  # Helper functions for the template
  defp role_color_class(:system), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  defp role_color_class(:user), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp role_color_class(:assistant), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  
  defp render_with_visible_tokens(text) do
    text
    |> String.replace("<|im_start|>", ~s(<span class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">&lt;|im_start|&gt;</span>))
    |> String.replace("<|im_end|>", ~s(<span class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">&lt;|im_end|&gt;</span>))
    |> String.replace("<|start|>", ~s(<span class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">&lt;|start|&gt;</span>))
    |> String.replace("<|end|>", ~s(<span class="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">&lt;|end|&gt;</span>))
    |> String.replace("</s>", ~s(<span class="bg-red-200 dark:bg-red-800 px-1 rounded">&lt;/s&gt;</span>))
    |> String.replace("<s>", ~s(<span class="bg-green-200 dark:bg-green-800 px-1 rounded">&lt;s&gt;</span>))
    |> String.replace("[INST]", ~s(<span class="bg-blue-200 dark:bg-blue-800 px-1 rounded">[INST]</span>))
    |> String.replace("[/INST]", ~s(<span class="bg-blue-200 dark:bg-blue-800 px-1 rounded">[/INST]</span>))
    |> Phoenix.HTML.raw()
  end
end