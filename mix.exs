defmodule Vectoree.MixProject do
  use Mix.Project

  @source_url "https://github.com/thjomnx/vectoree"

  def project do
    [
      app: :vectoree,
      version: "0.0.2",
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
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:benchee, "~> 1.3", only: :dev}
    ]
  end

  defp package do
    [
      name: "vectoree",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end
end
