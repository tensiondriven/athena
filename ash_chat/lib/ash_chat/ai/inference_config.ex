defmodule AshChat.AI.InferenceConfig do
  @moduledoc """
  Configuration management for LLM inference parameters and provider settings
  """

  @default_config %{
    provider: "openrouter",
    model: "qwen/qwen-2.5-72b-instruct",
    temperature: 0.7,
    top_p: 0.9,
    max_tokens: 2048,
    stream: true,
    frequency_penalty: 0.0,
    presence_penalty: 0.0,
    stop_sequences: [],
    seed: nil
  }

  def default_config, do: @default_config

  def get_providers do
    Application.get_env(:ash_chat, :llm_providers, %{})
  end

  def get_provider_config(provider_id) do
    get_providers()[provider_id]
  end

  def get_available_models(provider_id) do
    case provider_id do
      "ollama" -> fetch_ollama_models()
      _ ->
        case get_provider_config(provider_id) do
          %{models: models} -> models
          _ -> []
        end
    end
  end

  def fetch_ollama_models do
    base_url = Application.get_env(:langchain, :ollama_url, "http://10.1.2.200:11434")
    url = "#{base_url}/api/tags"
    
    case HTTPoison.get(url, [], timeout: 5000, recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"models" => models}} ->
            Enum.map(models, fn model -> model["name"] end)
          _ -> [@default_config.model]
        end
      _ -> 
        [@default_config.model]
    end
  rescue
    _ -> [@default_config.model]
  end

  def get_current_ollama_model do
    base_url = Application.get_env(:langchain, :ollama_url, "http://10.1.2.200:11434")
    url = "#{base_url}/api/ps"
    
    case HTTPoison.get(url, [], timeout: 5000, recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"models" => []}} -> nil
          {:ok, %{"models" => [model | _]}} -> model["name"]
          {:ok, %{"models" => models}} when is_list(models) and length(models) > 0 ->
            # Get the most recently used model (first in list)
            List.first(models)["name"]
          _ -> nil
        end
      _ -> nil
    end
  rescue
    _ -> nil
  end

  def validate_config(config) do
    validated = %{
      provider: validate_string(config[:provider], "ollama"),
      model: validate_string(config[:model], "llama3.2:latest"),
      temperature: validate_float(config[:temperature], 0.7, 0.0, 2.0),
      top_p: validate_float(config[:top_p], 0.9, 0.0, 1.0),
      max_tokens: validate_integer(config[:max_tokens], 2048, 1, 32000),
      stream: validate_boolean(config[:stream], true),
      frequency_penalty: validate_float(config[:frequency_penalty], 0.0, -2.0, 2.0),
      presence_penalty: validate_float(config[:presence_penalty], 0.0, -2.0, 2.0),
      stop_sequences: validate_list(config[:stop_sequences], []),
      seed: validate_optional_integer(config[:seed])
    }

    # For now, just return the validated config without checking available models
    # since the model list in config might not match the actual Ollama models
    validated
  end

  def create_chat_model_from_profile(profile, inference_params \\ %{}) do
    config = %{
      provider: profile.provider,
      model: profile.model,
      api_key: profile.api_key,
      url: profile.url
    }
    |> Map.merge(inference_params)
    
    create_chat_model(config)
  end

  def create_chat_model(config) do
    validated_config = validate_config(config)
    
    # Check if we should use OpenRouter instead of direct provider
    use_openrouter = Application.get_env(:ash_chat, :use_openrouter, true)
    
    # Override provider to openrouter if enabled and not already openrouter
    validated_config = if use_openrouter and validated_config.provider not in ["openrouter", "anthropic"] do
      Map.put(validated_config, :provider, "openrouter")
    else
      validated_config
    end
    
    provider_config = get_provider_config(validated_config.provider)

    case validated_config.provider do
      "ollama" ->
        alias LangChain.ChatModels.ChatOllamaAI
        
        # Get the endpoint URL from provider config or use default
        base_url = case provider_config do
          %{url: url} when is_binary(url) -> url
          _ -> Application.get_env(:langchain, :ollama_url, "http://10.1.2.200:11434")
        end
        
        # LangChain ChatOllamaAI expects the full endpoint including /api/chat
        endpoint = "#{base_url}/api/chat"
        
        ChatOllamaAI.new!(%{
          model: validated_config.model,
          endpoint: endpoint,
          temperature: validated_config.temperature,
          top_p: validated_config.top_p,
          stream: validated_config.stream
        })

      "openrouter" ->
        # OpenRouter uses OpenAI-compatible API
        alias LangChain.ChatModels.ChatOpenAI
        
        # Get API key
        api_key = Application.get_env(:langchain, :openrouter_key) || 
                  raise "OPENROUTER_API_KEY environment variable is not set"
        
        # Use the original requested model if it wasn't ollama
        model = if config[:provider] == "ollama" do
          # Map ollama models to openrouter equivalents
          case validated_config.model do
            "qwen2.5:latest" -> "qwen/qwen-2.5-72b-instruct"
            "llama3.2:latest" -> "meta-llama/llama-3.1-70b-instruct"
            "deepseek-coder:latest" -> "deepseek/deepseek-chat"
            _ -> "qwen/qwen-2.5-72b-instruct"  # Default fallback
          end
        else
          validated_config.model
        end
        
        ChatOpenAI.new!(%{
          model: model,
          endpoint: "https://openrouter.ai/api/v1/chat/completions",
          api_key: api_key,
          temperature: validated_config.temperature,
          top_p: validated_config.top_p,
          frequency_penalty: validated_config.frequency_penalty,
          presence_penalty: validated_config.presence_penalty,
          max_tokens: validated_config.max_tokens,
          stream: validated_config.stream,
          seed: validated_config.seed,
          api_org_id: nil  # OpenRouter doesn't use org ID
        })

      "openai" ->
        alias LangChain.ChatModels.ChatOpenAI
        ChatOpenAI.new!(%{
          model: validated_config.model,
          temperature: validated_config.temperature,
          top_p: validated_config.top_p,
          frequency_penalty: validated_config.frequency_penalty,
          presence_penalty: validated_config.presence_penalty,
          max_tokens: validated_config.max_tokens,
          stream: validated_config.stream,
          seed: validated_config.seed
        })

      "anthropic" ->
        alias LangChain.ChatModels.ChatAnthropic
        ChatAnthropic.new!(%{
          model: validated_config.model,
          temperature: validated_config.temperature,
          top_p: validated_config.top_p,
          max_tokens: validated_config.max_tokens,
          stream: validated_config.stream
        })

      _ ->
        # Default to OpenRouter if available, otherwise Ollama
        if Application.get_env(:langchain, :openrouter_key) do
          create_chat_model(Map.put(config, :provider, "openrouter"))
        else
          alias LangChain.ChatModels.ChatOllamaAI
          ChatOllamaAI.new!(%{
            model: "qwen2.5:latest",
            base_url: "http://10.1.2.200:11434",
            temperature: 0.7
          })
        end
    end
  end

  # Validation helpers
  defp validate_string(value, _default) when is_binary(value), do: value
  defp validate_string(_, default), do: default

  defp validate_float(value, _default, min, max) when is_number(value) do
    cond do
      value < min -> min
      value > max -> max
      true -> value * 1.0
    end
  end
  defp validate_float(_, default, _, _), do: default

  defp validate_integer(value, _default, min, max) when is_integer(value) do
    cond do
      value < min -> min
      value > max -> max
      true -> value
    end
  end
  defp validate_integer(value, default, min, max) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} -> validate_integer(int_val, default, min, max)
      _ -> default
    end
  end
  defp validate_integer(_, default, _, _), do: default

  defp validate_boolean(value, _default) when is_boolean(value), do: value
  defp validate_boolean(_, default), do: default

  defp validate_list(value, _default) when is_list(value), do: value
  defp validate_list(_, default), do: default

  defp validate_optional_integer(nil), do: nil
  defp validate_optional_integer(value) when is_integer(value), do: value
  defp validate_optional_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int_val, ""} -> int_val
      _ -> nil
    end
  end
  defp validate_optional_integer(_), do: nil
end