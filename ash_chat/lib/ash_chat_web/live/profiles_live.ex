defmodule AshChatWeb.ProfilesLive do
  use AshChatWeb, :live_view
  
  alias AshChat.CharacterCard

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(
       personas: load_personas(),
       system_prompts: load_system_prompts(),
       agent_cards: load_agent_cards(),
       show_persona_form: false,
       show_system_prompt_form: false,
       show_import_modal: false,
       editing_persona: nil,
       editing_system_prompt: nil,
       persona_form: to_form(%{}, as: :persona),
       system_prompt_form: to_form(%{}, as: :system_prompt),
       drag_over: false
     )
     |> allow_upload(:quick_import,
       accept: ~w(.json .png),
       max_entries: 1,
       max_file_size: 10_000_000,
       auto_upload: true
     )}
  end

  @impl true
  def handle_event("new_persona", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_persona_form: true,
       editing_persona: nil,
       persona_form: to_form(%{}, as: :persona)
     )}
  end

  @impl true
  def handle_event("edit_persona", %{"id" => id}, socket) do
    persona = Enum.find(socket.assigns.personas, &(&1.id == id))
    form_data = %{
      "name" => persona.name,
      "provider" => persona.provider,
      "url" => persona.url || "",
      "model" => persona.model || "",
      "is_default" => persona.is_default
    }
    
    {:noreply, 
     socket
     |> assign(
       show_persona_form: true,
       editing_persona: persona,
       persona_form: to_form(form_data, as: :persona)
     )}
  end

  @impl true
  def handle_event("save_persona", %{"persona" => persona_params}, socket) do
    result = if socket.assigns.editing_persona do
      AshChat.Resources.Persona.update(socket.assigns.editing_persona, persona_params)
    else
      AshChat.Resources.Persona.create(persona_params)
    end

    case result do
      {:ok, _persona} ->
        {:noreply,
         socket
         |> assign(
           personas: load_personas(),
           show_persona_form: false,
           editing_persona: nil
         )
         |> put_flash(:info, "Persona saved successfully")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save persona")}
    end
  end

  @impl true
  def handle_event("delete_persona", %{"id" => id}, socket) do
    persona = Enum.find(socket.assigns.personas, &(&1.id == id))
    
    case AshChat.Resources.Persona.destroy(persona) do
      :ok ->
        {:noreply,
         socket
         |> assign(personas: load_personas())
         |> put_flash(:info, "Persona deleted successfully")}
      
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete persona")}
    end
  end

  @impl true
  def handle_event("new_system_prompt", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_system_prompt_form: true,
       editing_system_prompt: nil,
       system_prompt_form: to_form(%{}, as: :system_prompt)
     )}
  end

  @impl true
  def handle_event("edit_system_prompt", %{"id" => id}, socket) do
    system_prompt = Enum.find(socket.assigns.system_prompts, &(&1.id == id))
    form_data = %{
      "name" => system_prompt.name,
      "content" => system_prompt.content,
      "description" => system_prompt.description || "",
      "persona_id" => system_prompt.persona_id,
      "is_active" => system_prompt.is_active,
      "version" => system_prompt.version || "",
      "version_notes" => system_prompt.version_notes || ""
    }
    
    {:noreply, 
     socket
     |> assign(
       show_system_prompt_form: true,
       editing_system_prompt: system_prompt,
       system_prompt_form: to_form(form_data, as: :system_prompt)
     )}
  end

  @impl true
  def handle_event("save_system_prompt", %{"system_prompt" => system_prompt_params}, socket) do
    result = if socket.assigns.editing_system_prompt do
      AshChat.Resources.SystemPrompt.update(socket.assigns.editing_system_prompt, system_prompt_params)
    else
      AshChat.Resources.SystemPrompt.create(system_prompt_params)
    end

    case result do
      {:ok, _system_prompt} ->
        {:noreply,
         socket
         |> assign(
           system_prompts: load_system_prompts(),
           show_system_prompt_form: false,
           editing_system_prompt: nil
         )
         |> put_flash(:info, "System prompt saved successfully")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save system prompt")}
    end
  end

  @impl true
  def handle_event("delete_system_prompt", %{"id" => id}, socket) do
    system_prompt = Enum.find(socket.assigns.system_prompts, &(&1.id == id))
    
    case AshChat.Resources.SystemPrompt.destroy(system_prompt) do
      :ok ->
        {:noreply,
         socket
         |> assign(system_prompts: load_system_prompts())
         |> put_flash(:info, "System prompt deleted successfully")}
      
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete system prompt")}
    end
  end

  @impl true
  def handle_event("duplicate_system_prompt", %{"id" => id}, socket) do
    system_prompt = Enum.find(socket.assigns.system_prompts, &(&1.id == id))
    
    # Calculate next version
    original_version = system_prompt.version || "1.0"
    next_version = calculate_next_version(original_version)
    
    # If this prompt has a parent, use that as the parent. Otherwise, this prompt becomes the parent.
    parent_id = system_prompt.parent_prompt_id || system_prompt.id
    
    duplicate_params = %{
      "name" => system_prompt.name,  # Keep the same name
      "content" => system_prompt.content,
      "description" => system_prompt.description,
      "persona_id" => system_prompt.persona_id,
      "is_active" => false,  # Set duplicate as inactive by default
      "version" => next_version,
      "version_notes" => "Duplicated from version #{original_version}",
      "parent_prompt_id" => parent_id
    }
    
    case AshChat.Resources.SystemPrompt.create(duplicate_params) do
      {:ok, _new_prompt} ->
        {:noreply,
         socket
         |> assign(system_prompts: load_system_prompts())
         |> put_flash(:info, "Created version #{next_version} of #{system_prompt.name}")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to duplicate agent persona")}
    end
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_persona_form: false,
       show_system_prompt_form: false,
       editing_persona: nil,
       editing_system_prompt: nil
     )}
  end
  
  @impl true
  def handle_event("show_import", _params, socket) do
    {:noreply, assign(socket, show_import_modal: true)}
  end
  
  @impl true
  def handle_event("hide_import", _params, socket) do
    {:noreply, assign(socket, show_import_modal: false)}
  end
  
  @impl true
  def handle_event("drag-enter", _params, socket) do
    {:noreply, assign(socket, drag_over: true)}
  end
  
  @impl true
  def handle_event("drag-leave", _params, socket) do
    {:noreply, assign(socket, drag_over: false)}
  end
  
  @impl true
  def handle_event("validate-quick-import", _params, socket) do
    # Handle file validation during drag & drop
    {:noreply, 
     socket
     |> assign(drag_over: false)
     |> handle_quick_import()}
  end
  
  @impl true
  def handle_info({:character_imported, agent_card}, socket) do
    {:noreply,
     socket
     |> assign(
       agent_cards: load_agent_cards(),
       system_prompts: load_system_prompts(),
       show_import_modal: false
     )
     |> put_flash(:info, "Successfully imported #{agent_card.name}!")}
  end
  
  defp handle_quick_import(socket) do
    consume_uploaded_entries(socket, :quick_import, fn %{path: path}, entry ->
      content = File.read!(path)
      
      result = case entry.client_type do
        "image/png" ->
          import_from_png(content)
        _ ->
          CharacterCard.import_json(content)
      end
      
      case result do
        {:ok, agent_card} ->
          send(self(), {:character_imported, agent_card})
          {:ok, agent_card}
          
        {:error, reason} ->
          {:postpone, reason}
      end
    end)
    
    socket
  end
  
  defp import_from_png(png_binary) do
    alias AshChat.PngMetadata
    
    with {:ok, character_data} <- PngMetadata.extract_character_data(png_binary),
         {:ok, agent_card} <- CharacterCard.import_character_data(character_data) do
      {:ok, agent_card}
    end
  end

  defp load_personas do
    AshChat.Resources.Persona.read!()
  end

  defp load_system_prompts do
    AshChat.Resources.SystemPrompt.read!()
    |> Ash.load!([:persona])
  end
  
  defp load_agent_cards do
    AshChat.Resources.AgentCard.read!()
    |> Ash.load!([:system_prompt])
  end

  defp calculate_next_version(current_version) do
    # Simple version incrementing logic
    case String.split(current_version, ".") do
      [major, minor] ->
        case Integer.parse(minor) do
          {minor_int, _} -> "#{major}.#{minor_int + 1}"
          _ -> "#{current_version}.1"
        end
      [major] ->
        case Integer.parse(major) do
          {major_int, _} -> "#{major_int + 1}"
          _ -> "#{current_version}.1"
        end
      _ ->
        # For complex versions like "2.0-beta", just append .1
        "#{current_version}.1"
    end
  end
end