defmodule AshChatWeb.ProfilesLive do
  use AshChatWeb, :live_view
  
  alias AshChat.CharacterCard
  alias AshChat.Resources.Persona

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(
       personas: load_personas(),
       show_persona_form: false,
       show_import_modal: false,
       editing_persona: nil,
       persona_form: to_form(%{}, as: :persona),
       drag_over: false,
       filter_type: nil,
       filter_tag: nil
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
       persona_form: to_form(%{
         "persona_type" => "assistant",
         "provider" => "ollama",
         "temperature" => "0.7",
         "max_tokens" => "500",
         "context_format" => "consolidated"
       }, as: :persona)
     )}
  end

  @impl true
  def handle_event("edit_persona", %{"id" => id}, socket) do
    persona = Enum.find(socket.assigns.personas, &(&1.id == id))
    form_data = Map.from_struct(persona)
    |> Map.drop([:__meta__, :__struct__, :id, :created_at, :updated_at, :inserted_at])
    |> Map.new(fn {k, v} -> 
      {to_string(k), format_form_value(v)}
    end)
    
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
    # Convert string keys to atoms and handle nested maps
    params = atomize_params(persona_params)
    
    result = if socket.assigns.editing_persona do
      Persona.update(socket.assigns.editing_persona, params)
    else
      Persona.create(params)
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
    
    case Persona.destroy(persona) do
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
  def handle_event("duplicate_persona", %{"id" => id}, socket) do
    persona = Enum.find(socket.assigns.personas, &(&1.id == id))
    
    # Calculate next version
    next_version = (persona.version || 1) + 1
    
    duplicate_params = Map.from_struct(persona)
    |> Map.drop([:__meta__, :__struct__, :id, :created_at, :updated_at])
    |> Map.put(:version, next_version)
    |> Map.put(:name, "#{persona.name} (v#{next_version})")
    
    case Persona.create(duplicate_params) do
      {:ok, _new_persona} ->
        {:noreply,
         socket
         |> assign(personas: load_personas())
         |> put_flash(:info, "Created version #{next_version} of #{persona.name}")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to duplicate persona")}
    end
  end

  @impl true
  def handle_event("filter_by_type", %{"type" => type}, socket) do
    filter = if type == "all", do: nil, else: String.to_atom(type)
    {:noreply, assign(socket, filter_type: filter)}
  end

  @impl true
  def handle_event("filter_by_tag", %{"tag" => tag}, socket) do
    filter = if tag == "all", do: nil, else: tag
    {:noreply, assign(socket, filter_tag: filter)}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_persona_form: false,
       editing_persona: nil
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
    {:noreply, 
     socket
     |> assign(drag_over: false)
     |> handle_quick_import()}
  end
  
  @impl true
  def handle_info({:character_imported, persona}, socket) do
    {:noreply,
     socket
     |> assign(
       personas: load_personas(),
       show_import_modal: false
     )
     |> put_flash(:info, "Successfully imported #{persona.name}!")}
  end
  
  def filtered_personas(personas, type_filter, tag_filter) do
    personas
    |> then(fn ps ->
      if type_filter do
        Enum.filter(ps, &(&1.persona_type == type_filter))
      else
        ps
      end
    end)
    |> then(fn ps ->
      if tag_filter do
        Enum.filter(ps, &(tag_filter in (&1.tags || [])))
      else
        ps
      end
    end)
  end
  
  def all_tags(personas) do
    personas
    |> Enum.flat_map(&(&1.tags || []))
    |> Enum.uniq()
    |> Enum.sort()
  end
  
  def persona_type_label(type) do
    case type do
      :assistant -> "AI Assistant"
      :expert -> "Expert"
      :friend -> "Friend"
      :employee -> "Employee"
      :character -> "Character"
      :visitor -> "Visitor"
      :guest -> "Guest"
      _ -> to_string(type)
    end
  end
  
  def persona_type_color(type) do
    case type do
      :assistant -> "blue"
      :expert -> "purple"
      :friend -> "green"
      :employee -> "orange"
      :character -> "pink"
      :visitor -> "gray"
      :guest -> "yellow"
      _ -> "gray"
    end
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
        {:ok, persona} ->
          send(self(), {:character_imported, persona})
          {:ok, persona}
          
        {:error, reason} ->
          {:postpone, reason}
      end
    end)
    
    socket
  end
  
  defp import_from_png(png_binary) do
    alias AshChat.PngMetadata
    
    with {:ok, character_data} <- PngMetadata.extract_character_data(png_binary),
         {:ok, persona} <- CharacterCard.import_character_data(character_data) do
      {:ok, persona}
    end
  end

  defp load_personas do
    Persona.read!()
    |> Enum.sort_by(&{&1.persona_type, &1.name})
  end
  
  defp format_form_value(nil), do: ""
  defp format_form_value(v) when is_map(v), do: Jason.encode!(v)
  defp format_form_value(v) when is_list(v) do
    case v do
      [] -> ""
      [h | _] when is_atom(h) -> v |> Enum.map(&to_string/1) |> Enum.join(", ")
      _ -> Enum.join(v, ", ")
    end
  end
  defp format_form_value(v) when is_atom(v), do: to_string(v)
  defp format_form_value(v), do: to_string(v)

  defp atomize_params(params) when is_map(params) do
    params
    |> Enum.map(fn {k, v} ->
      key = if is_binary(k), do: String.to_atom(k), else: k
      value = case {k, v} do
        {_, v} when is_map(v) -> atomize_params(v)
        {"tags", tags} when is_binary(tags) -> 
          tags |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.filter(&(&1 != ""))
        {"capabilities", caps} when is_binary(caps) ->
          caps |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.map(&String.to_atom/1)
        {"temperature", temp} when is_binary(temp) -> String.to_float(temp)
        {"max_tokens", tokens} when is_binary(tokens) -> String.to_integer(tokens)
        {"context_window", window} when is_binary(window) -> String.to_integer(window)
        {"auto_respond", "true"} -> true
        {"auto_respond", "false"} -> false
        _ -> v
      end
      {key, value}
    end)
    |> Enum.into(%{})
  end
  defp atomize_params(params), do: params
end