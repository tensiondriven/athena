defmodule ClaudeCollector.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Neo4j Connection
      {Bolt.Sips, bolt_config()},
      
      # HTTP Server
      {Plug.Cowboy, scheme: :http, plug: ClaudeCollector.Router, options: [port: 4000]},
      
      # Chat Log Monitor
      ClaudeCollector.ChatLogMonitor,
      
      # Event Publisher Broadway Pipeline
      ClaudeCollector.EventPublisher,
      
      # Statistics GenServer
      ClaudeCollector.Statistics
    ]

    opts = [strategy: :one_for_one, name: ClaudeCollector.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp bolt_config do
    [
      url: System.get_env("NEO4J_URI", "bolt://localhost:7687"),
      basic_auth: [
        username: System.get_env("NEO4J_USERNAME", "neo4j"),
        password: System.get_env("NEO4J_PASSWORD", "athena-knowledge")
      ],
      pool_size: 10,
      max_overflow: 5
    ]
  end
end