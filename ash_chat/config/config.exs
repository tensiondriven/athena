# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Load environment variables from .env file in development and test
if Mix.env() in [:dev, :test] do
  try do
    Code.ensure_loaded(Dotenv)
    if function_exported?(Dotenv, :load, 0) do
      Dotenv.load()
    end
  rescue
    _ -> :ok
  end
end

config :ash_chat,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :ash_chat, AshChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AshChatWeb.ErrorHTML, json: AshChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AshChat.PubSub,
  live_view: [signing_salt: "kwbkIQuP"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ash_chat, AshChat.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ash_chat: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  ash_chat: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure AshAI
config :ash_ai, :vector_store, 
  module: AshAi.VectorStores.Ets,  # Use ETS for development
  table: "embeddings"

# Configure Ash domains
config :ash_chat, ash_domains: [AshChat.Domain]

# Configure LangChain
config :langchain, :openai_key, System.get_env("OPENAI_API_KEY")
config :langchain, :anthropic_key, System.get_env("ANTHROPIC_API_KEY")

# Configure Ollama
config :langchain, :ollama_url, System.get_env("OLLAMA_URL", "http://10.1.2.200:11434")

# Configure provider defaults
config :ash_chat, :llm_providers, %{
  "ollama" => %{
    name: "Ollama (Local)",
    url: System.get_env("OLLAMA_URL", "http://10.1.2.200:11434"),
    models: ["llama3.2", "qwen2.5", "deepseek-coder", "codestral"]
  },
  "openai" => %{
    name: "OpenAI",
    url: "https://api.openai.com/v1",
    models: ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
  },
  "anthropic" => %{
    name: "Anthropic",
    url: "https://api.anthropic.com",
    models: ["claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"]
  }
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
