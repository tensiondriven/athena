defmodule AshChat.AI.InferenceConfig do
  @moduledoc """
  Configuration management for LLM inference parameters and provider settings
  """

  @default_config %{
    provider: "ollama",
    model: "qwen2.5:latest",
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
    case get_provider_config(provider_id) do
      %{models: models} -> models
      _ -> []
    end
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
        # Default to Ollama
        alias LangChain.ChatModels.ChatOllamaAI
        ChatOllamaAI.new!(%{
          model: "qwen2.5:latest",
          base_url: "http://10.1.2.200:11434",
          temperature: 0.7
        })
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