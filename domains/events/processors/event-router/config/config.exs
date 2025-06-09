import Config

config :logger, :console,
  format: "[$level] $message\n",
  level: :info

config :claude_collector,
  athena_endpoint: System.get_env("ATHENA_ENDPOINT", "http://athena-capture:8080/events"),
  neo4j_uri: System.get_env("NEO4J_URI", "bolt://10.1.2.200:7687"),
  neo4j_username: System.get_env("NEO4J_USERNAME", "neo4j"),
  neo4j_password: System.get_env("NEO4J_PASSWORD", "athena-knowledge")
