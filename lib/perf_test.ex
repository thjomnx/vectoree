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

    IO.puts("Enum.map")

    Enum.map(
      0..99999,
      fn i ->
        name = "node_" <> Integer.to_string(i)
        DataTree.insert(:ptree, ~n"data.#{name}")
      end
    )

    IO.puts("DataTree.subtree")

    sub = DataTree.subtree(:ptree, ~p"data")
    length(sub) |> IO.puts()
  end

  def populate do
    IO.puts("DataTree.populate")

    DataTree.new(name: :ptree)

    start = DateTime.utc_now()
    DataTree.populate(:ptree)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTree.subtree")

    start = DateTime.utc_now()

    case DataTree.subtree(:ptree, ~p"data") do
      {:ok, sub} ->
        DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
        length(sub) |> IO.puts()

      {:error, reason} ->
        IO.puts(reason)
    end
  end
end
