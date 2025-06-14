defmodule AshChatWeb.CharacterImportComponent do
  use AshChatWeb, :live_component
  
  alias AshChat.CharacterCard
  
  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:uploaded_files, [])
     |> allow_upload(:character_file,
       accept: ~w(.json .png),
       max_entries: 1,
       max_file_size: 10_000_000  # 10MB max for PNG files
     )}
  end
  
  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end
  
  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :character_file, ref)}
  end
  
  @impl true
  def handle_event("import", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :character_file, fn %{path: path}, entry ->
        content = File.read!(path)
        {:ok, {content, entry.client_type}}
      end)
    
    case uploaded_files do
      [{content, type}] ->
        result = case type do
          "image/png" ->
            import_from_png(content)
          _ ->
            # Assume JSON for any other type
            CharacterCard.import_json(content)
        end
        
        case result do
          {:ok, agent_card} ->
            send(self(), {:character_imported, agent_card})
            {:noreply, socket}
             
          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Import failed: #{reason}")}
        end
        
      [] ->
        {:noreply,
         socket
         |> put_flash(:error, "Please select a file to import")}
    end
  end
  
  defp import_from_png(png_binary) do
    alias AshChat.PngMetadata
    
    with {:ok, character_data} <- PngMetadata.extract_character_data(png_binary),
         {:ok, agent_card} <- CharacterCard.import_character_data(character_data) do
      {:ok, agent_card}
    else
      {:error, reason} -> {:error, "PNG import failed: #{reason}"}
    end
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Import SillyTavern Character
        <:subtitle>Upload a JSON character card file</:subtitle>
      </.header>
      
      <div class="mt-6">
        <form id="upload-form" phx-submit="import" phx-change="validate" phx-target={@myself}>
          <div class="space-y-4">
            <div class="border-2 border-dashed border-gray-300 rounded-lg p-6">
              <div class="text-center">
                <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                  <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
                
                <div class="mt-4">
                  <label for="file-upload" class="cursor-pointer">
                    <span class="mt-2 block text-sm font-medium text-gray-900">
                      Click to upload or drag and drop
                    </span>
                    <.live_file_input upload={@uploads.character_file} class="sr-only" />
                  </label>
                  <p class="text-xs text-gray-500">JSON or PNG files up to 10MB</p>
                </div>
              </div>
              
              <%= for entry <- @uploads.character_file.entries do %>
                <div class="mt-4 flex items-center justify-between p-3 bg-gray-50 rounded">
                  <span class="text-sm text-gray-600"><%= entry.client_name %></span>
                  <button
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    phx-target={@myself}
                    class="text-red-600 hover:text-red-800"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
                
                <%= for err <- upload_errors(@uploads.character_file, entry) do %>
                  <p class="text-red-600 text-sm mt-1"><%= error_to_string(err) %></p>
                <% end %>
              <% end %>
            </div>
            
            <div class="flex justify-end gap-4">
              <.button type="button" phx-click="hide_import">
                Cancel
              </.button>
              <.button type="submit" disabled={@uploads.character_file.entries == []}>
                Import Character
              </.button>
            </div>
          </div>
        </form>
      </div>
      
      <div class="mt-8 text-sm text-gray-600">
        <h4 class="font-medium mb-2">Supported Formats:</h4>
        <ul class="list-disc list-inside space-y-1">
          <li>SillyTavern V1 JSON format</li>
          <li>SillyTavern V2 JSON format (recommended)</li>
          <li>PNG files with embedded character data</li>
          <li>Character cards exported from SillyTavern, TavernAI, or compatible tools</li>
        </ul>
      </div>
    </div>
    """
  end
  
  defp error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp error_to_string(:not_accepted), do: "Only JSON and PNG files are accepted"
  defp error_to_string(err), do: "Error: #{inspect(err)}"
end