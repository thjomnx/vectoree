defmodule DataTree.MixProject do
  use Mix.Project

  def project do
    [
      app: :datatree,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
#      applications: [:shards],
      extra_applications: [:logger],
      mod: {DataTree.Tryout, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
#      {:ex_shards, "~> 0.2"},
#      {:ex2ms, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
