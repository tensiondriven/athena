defmodule ClaudeCollector.MixProject do
  use Mix.Project

  def project do
    [
      app: :claude_collector,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :httpoison],
      mod: {ClaudeCollector.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:plug_cowboy, "~> 2.5"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.0"},
      {:gen_stage, "~> 1.2"},
      {:broadway, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.0"},
      {:bolt_sips, "~> 2.0"},
      {:file_system, "~> 0.2"}
    ]
  end
end