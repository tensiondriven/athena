defmodule AshChat.Setup do
  @moduledoc """
  Setup and seed initial data for AshChat
  """
  
  alias AshChat.Resources.Profile
  
  def create_default_profiles do
    # Create default profiles if they don't exist
    ollama_profile = %{
      name: "Ollama Local",
      provider: "ollama", 
      url: System.get_env("OLLAMA_URL", "http://10.1.2.200:11434"),
      model: "qwen2.5:latest",
      is_default: true
    }
    
    openai_profile = %{
      name: "OpenAI GPT-4o",
      provider: "openai",
      url: "https://api.openai.com/v1", 
      api_key: System.get_env("OPENAI_API_KEY"),
      model: "gpt-4o"
    }
    
    anthropic_profile = %{
      name: "Anthropic Claude",
      provider: "anthropic",
      url: "https://api.anthropic.com",
      api_key: System.get_env("ANTHROPIC_API_KEY"), 
      model: "claude-3-5-sonnet-20241022"
    }
    
    # Only create if they don't exist
    case Profile.read() do
      {:ok, []} ->
        {:ok, _} = Profile.create(ollama_profile)
        {:ok, _} = Profile.create(openai_profile) 
        {:ok, _} = Profile.create(anthropic_profile)
        :ok
      {:ok, _profiles} ->
        :already_exists
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  def get_default_profile do
    case Profile.get_default() do
      {:ok, [profile]} -> {:ok, profile}
      {:ok, []} ->
        # No default set, create profiles and return first
        create_default_profiles()
        case Profile.read() do
          {:ok, [profile | _]} -> {:ok, profile}
          _ -> {:error, :no_profiles}
        end
      error -> error
    end
  end
end