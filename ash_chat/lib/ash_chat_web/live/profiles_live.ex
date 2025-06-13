defmodule AshChatWeb.ProfilesLive do
  use AshChatWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(
       profiles: load_profiles(),
       system_prompts: load_system_prompts(),
       show_profile_form: false,
       show_system_prompt_form: false,
       editing_profile: nil,
       editing_system_prompt: nil,
       profile_form: to_form(%{}, as: :profile),
       system_prompt_form: to_form(%{}, as: :system_prompt)
     )}
  end

  @impl true
  def handle_event("new_profile", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_profile_form: true,
       editing_profile: nil,
       profile_form: to_form(%{}, as: :profile)
     )}
  end

  @impl true
  def handle_event("edit_profile", %{"id" => id}, socket) do
    profile = Enum.find(socket.assigns.profiles, &(&1.id == id))
    form_data = %{
      "name" => profile.name,
      "provider" => profile.provider,
      "url" => profile.url || "",
      "model" => profile.model || "",
      "is_default" => profile.is_default
    }
    
    {:noreply, 
     socket
     |> assign(
       show_profile_form: true,
       editing_profile: profile,
       profile_form: to_form(form_data, as: :profile)
     )}
  end

  @impl true
  def handle_event("save_profile", %{"profile" => profile_params}, socket) do
    result = if socket.assigns.editing_profile do
      AshChat.Resources.Profile.update(socket.assigns.editing_profile, profile_params)
    else
      AshChat.Resources.Profile.create(profile_params)
    end

    case result do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> assign(
           profiles: load_profiles(),
           show_profile_form: false,
           editing_profile: nil
         )
         |> put_flash(:info, "Profile saved successfully")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save profile")}
    end
  end

  @impl true
  def handle_event("delete_profile", %{"id" => id}, socket) do
    profile = Enum.find(socket.assigns.profiles, &(&1.id == id))
    
    case AshChat.Resources.Profile.destroy(profile) do
      :ok ->
        {:noreply,
         socket
         |> assign(profiles: load_profiles())
         |> put_flash(:info, "Profile deleted successfully")}
      
      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete profile")}
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
      "profile_id" => system_prompt.profile_id,
      "is_active" => system_prompt.is_active
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
  def handle_event("cancel_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(
       show_profile_form: false,
       show_system_prompt_form: false,
       editing_profile: nil,
       editing_system_prompt: nil
     )}
  end

  defp load_profiles do
    AshChat.Resources.Profile.read!()
  end

  defp load_system_prompts do
    AshChat.Resources.SystemPrompt.read!()
    |> Ash.load!([:profile])
  end
end