defmodule Crew.MixProject do
  use Mix.Project

  def project do
    [
      app: :crew,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:gen_stage, "~> 0.12"},
      {:timex, "~> 3.2"},
      {:crontab, "~> 1.1"},
      {:poison, "~> 3.0"},

      # Azure
      {:sweet_xml, "~> 0.6"},
      {:xml_builder, "~> 2.0"},
      {:httpoison, "~> 0.13"},
    ]
  end
end
