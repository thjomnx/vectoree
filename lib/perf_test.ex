defmodule PerfTest do
  use Application

  import DataTree.{Node, TreePath}

  def start(_type, _args) do
    insert_many()
    {:ok, self()}
  end

  def insert_many do
    DataTree.new(name: :ptree)

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

  def populate do
    IO.puts "DataTree.populate"

    DataTree.new(name: :ptree)
    DataTree.populate(:ptree)

    IO.puts "DataTree.subtree"

    {:ok, sub} = DataTree.subtree(:ptree, ~t"data")
    length(sub) |> IO.puts()
  end
end
