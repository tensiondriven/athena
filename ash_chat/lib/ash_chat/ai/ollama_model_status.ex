defmodule AshChat.AI.OllamaModelStatus do
  @moduledoc """
  Module for detecting Ollama model loading states.
  
  Based on API research, Ollama provides model loading information through:
  1. load_duration field in generate/chat responses
  2. Streaming status updates during model pull operations
  3. Model listing through /api/tags endpoint
  
  Key findings:
  - A model is loading if load_duration > 0 in the response
  - A model is already loaded if load_duration is 0 or missing
  - Download progress is available through /api/pull streaming
  """
  
  require Logger
  
  @ollama_host System.get_env("OLLAMA_HOST", "http://localhost:11434")
  
  @doc """
  Check if a model is available and get its status.
  Returns {:ok, status_map} or {:error, reason}
  
  Status map includes:
  - available: boolean indicating if model exists locally
  - size: model size in bytes
  - modified_at: last modification time
  """
  def check_model_availability(model_name) do
    case HTTPoison.get("#{@ollama_host}/api/tags") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"models" => models}} ->
            model = Enum.find(models, fn m -> m["name"] == model_name end)
            if model do
              {:ok, %{
                available: true,
                size: model["size"],
                modified_at: model["modified_at"],
                digest: model["digest"]
              }}
            else
              {:ok, %{available: false}}
            end
          _ ->
            {:error, "Failed to parse response"}
        end
      {:ok, response} ->
        {:error, "Unexpected status: #{response.status_code}"}
      {:error, error} ->
        {:error, "Connection failed: #{inspect(error)}"}
    end
  end
  
  @doc """
  Test if a model needs to be loaded by making a minimal request.
  Returns loading status information.
  
  Response includes:
  - was_loaded: true if model was loaded for this request
  - load_duration_ms: time spent loading (if loaded)
  - already_in_memory: true if model was already loaded
  """
  def test_model_loading_status(model_name) do
    request_body = %{
      model: model_name,
      prompt: "test",
      stream: false,
      # Use a very short keep_alive to test loading
      keep_alive: "1s"
    }
    
    start_time = System.monotonic_time(:millisecond)
    
    case HTTPoison.post(
      "#{@ollama_host}/api/generate",
      Jason.encode!(request_body),
      [{"Content-Type", "application/json"}],
      recv_timeout: 30_000
    ) do
      {:ok, %{status_code: 200, body: body}} ->
        end_time = System.monotonic_time(:millisecond)
        total_request_time = end_time - start_time
        
        case Jason.decode(body) do
          {:ok, response} ->
            load_duration = response["load_duration"] || 0
            load_duration_ms = load_duration / 1_000_000
            
            {:ok, %{
              was_loaded: load_duration > 0,
              load_duration_ms: load_duration_ms,
              already_in_memory: load_duration == 0,
              total_request_time_ms: total_request_time,
              model: response["model"],
              created_at: response["created_at"]
            }}
          _ ->
            {:error, "Failed to parse response"}
        end
      {:ok, response} ->
        {:error, "Model request failed: #{response.status_code}"}
      {:error, error} ->
        {:error, "Connection failed: #{inspect(error)}"}
    end
  end
  
  @doc """
  Monitor model pull/download progress.
  Streams progress updates to the caller.
  
  Options:
  - insecure: allow insecure connections (default: false)
  """
  def pull_model_with_progress(model_name, callback_fn \\ &IO.inspect/1) do
    request_body = %{
      name: model_name,
      stream: true
    }
    
    # Use streaming request to get progress updates
    case HTTPoison.post(
      "#{@ollama_host}/api/pull",
      Jason.encode!(request_body),
      [{"Content-Type", "application/json"}],
      stream_to: self(),
      async: :once
    ) do
      {:ok, %HTTPoison.AsyncResponse{id: id}} ->
        stream_pull_progress(id, callback_fn)
      {:error, error} ->
        {:error, "Failed to start pull: #{inspect(error)}"}
    end
  end
  
  defp stream_pull_progress(id, callback_fn, buffer \\ "") do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: code} ->
        if code == 200 do
          HTTPoison.stream_next(id)
          stream_pull_progress(id, callback_fn, buffer)
        else
          {:error, "Pull failed with status: #{code}"}
        end
        
      %HTTPoison.AsyncHeaders{id: ^id} ->
        HTTPoison.stream_next(id)
        stream_pull_progress(id, callback_fn, buffer)
        
      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        # Handle streaming JSON responses (one per line)
        new_buffer = buffer <> chunk
        {remaining, processed} = process_json_lines(new_buffer, callback_fn)
        
        HTTPoison.stream_next(id)
        stream_pull_progress(id, callback_fn, remaining)
        
      %HTTPoison.AsyncEnd{id: ^id} ->
        # Process any remaining buffer
        if buffer != "" do
          process_json_lines(buffer <> "\n", callback_fn)
        end
        {:ok, :completed}
        
    after
      30_000 ->
        {:error, :timeout}
    end
  end
  
  defp process_json_lines(buffer, callback_fn) do
    lines = String.split(buffer, "\n", trim: false)
    
    # Process complete lines
    {incomplete, complete} = 
      if List.last(lines) == "" do
        # Buffer ends with newline, all lines are complete
        {[], Enum.drop(lines, -1)}
      else
        # Last line is incomplete
        {List.last(lines), Enum.drop(lines, -1)}
      end
    
    # Parse and callback for each complete line
    Enum.each(complete, fn line ->
      if line != "" do
        case Jason.decode(line) do
          {:ok, data} ->
            status = parse_pull_status(data)
            callback_fn.(status)
          {:error, _} ->
            Logger.debug("Failed to parse pull response line: #{line}")
        end
      end
    end)
    
    {incomplete, complete}
  end
  
  defp parse_pull_status(data) do
    %{
      status: data["status"],
      digest: data["digest"],
      total: data["total"],
      completed: data["completed"],
      progress: calculate_progress(data["completed"], data["total"])
    }
  end
  
  defp calculate_progress(nil, _), do: nil
  defp calculate_progress(_, nil), do: nil
  defp calculate_progress(completed, total) when total > 0 do
    Float.round(completed / total * 100, 2)
  end
  defp calculate_progress(_, _), do: 0.0
  
  @doc """
  Preload a model into memory and keep it loaded.
  This is useful for ensuring a model is ready before use.
  """
  def preload_model(model_name, keep_alive \\ "5m") do
    request_body = %{
      model: model_name,
      prompt: "",
      keep_alive: keep_alive
    }
    
    case HTTPoison.post(
      "#{@ollama_host}/api/generate",
      Jason.encode!(request_body),
      [{"Content-Type", "application/json"}],
      recv_timeout: 60_000
    ) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, response} ->
            load_duration = response["load_duration"] || 0
            {:ok, %{
              model_loaded: true,
              load_duration_ms: load_duration / 1_000_000,
              keep_alive: keep_alive
            }}
          _ ->
            {:error, "Failed to parse response"}
        end
      {:ok, response} ->
        {:error, "Preload failed: #{response.status_code}"}
      {:error, error} ->
        {:error, "Connection failed: #{inspect(error)}"}
    end
  end
  
  @doc """
  Get comprehensive model status including availability and loading state.
  """
  def get_model_status(model_name) do
    with {:ok, availability} <- check_model_availability(model_name),
         {:ok, loading_status} <- test_model_loading_status(model_name) do
      {:ok, Map.merge(availability, loading_status)}
    else
      error -> error
    end
  end
end