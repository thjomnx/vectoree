defmodule Vectoree.MixProject do
  use Mix.Project

  @source_url "https://github.com/thjomnx/vectoree"

  def project do
    [
      app: :vectoree,
      version: "0.0.1",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Vectoree",
      description: "A tree-ish data structure, crammed into maps",
      source_url: @source_url,
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchee, "~> 1.1", only: :dev}
    ]
  end

  defp package do
    [
      name: "Vectoree",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
