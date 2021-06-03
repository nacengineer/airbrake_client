defmodule Airbrake.Mixfile do
  use Mix.Project

  def project do
    [
      app: :airbrake_client,
      version: "0.8.2",
      elixir: "~> 1.7",
      package: package(),
      description: """
        Elixir notifier to Airbrake.io (or Errbit) with plugs for Phoenix for automatic reporting.
      """,
      deps: deps(),
      docs: docs()
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  def package do
    [
      contributors: ["Jeremy D. Frens", "Clifton McIntosh", "Roman Smirnov"],
      maintainers: ["CityBase, Inc."],
      licenses: ["LGPL"],
      links: %{github: "https://github.com/CityBaseInc/airbrake_client"}
    ]
  end

  def application do
    [mod: {Airbrake, []}, applications: [:httpoison]]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9 or ~> 1.0"},
      {:poison, ">= 2.0.0", optional: true},
      {:ex_doc, "~> 0.19", only: [:dev, :test]}
    ]
  end
end
