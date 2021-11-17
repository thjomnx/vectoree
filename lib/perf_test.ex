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
      0..9999,
      fn i ->
        name = "node_" <> Integer.to_string(i)
        DataTree.insert(:ptree, ~n"data.#{name}")
      end
    )

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

  def populate do
    IO.puts("DataTree.populate")

    DataTree.new(name: :ptree)

    start = DateTime.utc_now()

    for i <- 1..100, j <- 1..100, k <- 1..20 do
      DataTree.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
    end

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

  def update_many do
    IO.puts("DataTree.update_many")

    path = ~p"data.23.42.node_11"
    start = DateTime.utc_now()

    for i <- 1..10_000_000 do
      DataTree.update_value(:ptree, path, i)
    end

    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
  end
end
