defmodule PerfTest do
  use Application

  import DataTree.{Node, TreePath}

  def start(_type, _args) do
    run()
    {:ok, self()}
  end

  def run do
    DataTree.start_link(name: :ptree)

    {:ok, _data} = DataTree.insert(:ptree, ~n"data")

    IO.puts "Enum.map"

    Enum.map(
      0..99999,
      fn i ->
        name = "node_" <> Integer.to_string(i)
        DataTree.insert(:ptree, ~n"data.#{name}")
      end
    )

    IO.puts "DataTree.subtree"

    sub = DataTree.subtree(:ptree, ~t"data")
    length(sub) |> IO.puts()
  end
end
