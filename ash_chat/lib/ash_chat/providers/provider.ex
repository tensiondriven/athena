defmodule AshChat.Provider do
  @moduledoc """
  Behavior for AI provider implementations.
  Each provider (Ollama, OpenRouter, Claude) implements this behavior.
  """
  
  @type companion :: AshChat.Resources.Companion.t()
  @type context :: list(map())
  @type opts :: keyword()
  @type response :: {:ok, String.t()} | {:error, any()}
  
  @doc """
  Send a message to the AI provider and get a response.
  
  ## Parameters
    - companion: The Companion resource with provider configuration
    - context: List of messages in the format expected by the provider
    - opts: Additional options like streaming, timeout, etc.
  """
  @callback send_message(companion, context, opts) :: response
  
  @doc """
  Format the context according to provider preferences.
  Some providers have specific formatting requirements.
  """
  @callback format_context(companion, messages :: list()) :: context
  
  @doc """
  Check if the provider is available and configured correctly.
  """
  @callback health_check(companion) :: {:ok, map()} | {:error, String.t()}
end