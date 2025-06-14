defmodule AshChat.Providers.Ollama do
  @moduledoc """
  Ollama provider implementation for local model inference.
  """
  
  @behaviour AshChat.Provider
  
  require Logger
  
  @impl true
  def send_message(companion, context, opts \\ []) do
    url = "#{companion.endpoint}/api/chat"
    
    body = %{
      model: companion.model,
      messages: context,
      temperature: companion.temperature,
      max_tokens: companion.max_tokens,
      top_p: companion.top_p,
      stream: opts[:stream] || false
    }
    |> remove_nil_values()
    
    headers = [{"Content-Type", "application/json"}]
    
    case HTTPoison.post(url, Jason.encode!(body), headers, recv_timeout: 60_000) do
      {:ok, %{status_code: 200, body: response_body}} ->
        handle_response(response_body, opts[:stream] || false)
        
      {:ok, %{status_code: status_code, body: error_body}} ->
        {:error, "Ollama error (#{status_code}): #{error_body}"}
        
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error: #{inspect(reason)}"}
    end
  end
  
  @impl true
  def format_context(companion, messages) do
    case companion.context_format do
      :consolidated ->
        format_consolidated(companion, messages)
      :message_per_message ->
        format_message_per_message(companion, messages)
      _ ->
        format_message_per_message(companion, messages)
    end
  end
  
  @impl true
  def health_check(companion) do
    url = "#{companion.endpoint}/api/tags"
    
    case HTTPoison.get(url, [], recv_timeout: 5_000) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, data} ->
            models = Enum.map(data["models"] || [], & &1["name"])
            {:ok, %{available: true, models: models}}
          _ ->
            {:ok, %{available: true, models: []}}
        end
        
      _ ->
        {:error, "Cannot connect to Ollama at #{companion.endpoint}"}
    end
  end
  
  # Private functions
  
  defp handle_response(body, false) do
    case Jason.decode(body) do
      {:ok, %{"message" => %{"content" => content}}} ->
        {:ok, content}
      {:ok, data} ->
        {:error, "Unexpected response format: #{inspect(data)}"}
      {:error, error} ->
        {:error, "JSON decode error: #{inspect(error)}"}
    end
  end
  
  defp handle_response(body, true) do
    # For streaming, we'd need to handle Server-Sent Events
    # For now, just parse the first complete response
    {:ok, body}
  end
  
  defp format_consolidated(companion, messages) do
    recent_messages = Enum.take(messages, -companion.context_window)
    
    history = recent_messages
    |> Enum.map(fn msg -> 
      role = if msg.user_id, do: "User", else: "Assistant"
      "#{role}: #{msg.content}"
    end)
    |> Enum.join("\n")
    
    [
      %{"role" => "system", "content" => companion.system_prompt},
      %{"role" => "user", "content" => history}
    ]
  end
  
  defp format_message_per_message(companion, messages) do
    recent_messages = Enum.take(messages, -companion.context_window)
    
    system_message = %{"role" => "system", "content" => companion.system_prompt}
    
    formatted_messages = Enum.map(recent_messages, fn msg ->
      role = if msg.user_id, do: "user", else: "assistant"
      %{"role" => role, "content" => msg.content}
    end)
    
    [system_message | formatted_messages]
  end
  
  defp remove_nil_values(map) do
    map
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(%{})
  end
end