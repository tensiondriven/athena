import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ash_chat, AshChatWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "YHG3QNHJuA5ROtdtzpFY4TrxlDYUGSBiKy+jV8BjM0qH8c+qtWJyCYgEkULyPZkj",
  server: false

# In test we don't send emails
config :ash_chat, AshChat.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print info messages during test for debugging
config :logger, level: :info

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
