defmodule PTZConnector.MixProject do
  use Mix.Project

  def project do
    [
      app: :ptz_connector,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {PTZConnector.Application, []}
    ]
  end

  defp deps do
    [
      # MQTT client for agent communication
      {:emqtt, "~> 1.12"},
      # JSON encoding/decoding
      {:jason, "~> 1.4"},
      # UUID generation for command IDs
      {:uuid, "~> 1.1"}
    ]
  end

  defp releases do
    [
      ptz_connector: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        steps: [:assemble, :tar]
      ]
    ]
  end
end