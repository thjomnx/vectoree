defmodule PerfTest do
  use Application

  import DataTree.{Node, TreePath}

  alias DataTree.{Node, TreePath}

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

  def populate_ets_set do
    IO.puts("DataTree.populate")

    DataTree.new(name: :ptree)

    start = DateTime.utc_now()
    DataTree.populate(:ptree)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTree.subtree")
    # Process.sleep(3000)

    start = DateTime.utc_now()
    {:ok, sub} = DataTree.subtree(:ptree, ~p"data")
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    length(sub) |> IO.puts()
    # sub |> IO.inspect()
  end

  def populate_sep_ets_set do
    IO.puts("DataTreeSep.populate")

    DataTreeSep.new(name: :ptree)

    start = DateTime.utc_now()
    DataTreeSep.populate(:ptree)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTreeSep.subtree")
    # Process.sleep(3000)

    start = DateTime.utc_now()
    {:ok, sub} = DataTreeSep.subtree(:ptree, ~p"data")
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    length(sub) |> IO.puts()
    # sub |> IO.inspect()
  end

  def populate_shards do
    IO.puts("DataTreeShards.populate")

    DataTreeShards.new(name: :ptree)

    start = DateTime.utc_now()
    DataTreeShards.populate(:ptree)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTreeShards.subtree")
    # Process.sleep(3000)

    start = DateTime.utc_now()
    {:ok, sub} = DataTreeShards.subtree(:ptree, ~p"data")
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    length(sub) |> IO.puts()
    # sub |> IO.inspect()
  end

  def populate_bag do
    IO.puts("DataTreeBag.populate")

    DataTreeBag.new(name: :ptree)

    start = DateTime.utc_now()
    DataTreeBag.populate(:ptree)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTreeBag.subtree")

    start = DateTime.utc_now()
    {:ok, sub} = DataTreeBag.subtree(:ptree, ~p"data")
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    length(sub) |> IO.puts()
    # sub |> IO.inspect()
  end

  def populate_map do
    IO.puts("DataTreeMap.populate")

    m = DataTreeMap.new()

    start = DateTime.utc_now()
    m = DataTreeMap.populate(m)
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    IO.puts("DataTreeMap.subtree")

    start = DateTime.utc_now()
    {:ok, sub} = DataTreeMap.subtree(m, ~p"data")
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    length(sub) |> IO.puts()
    # sub |> IO.inspect()
  end

  def bench_map do
    m =
      for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
        segments = ["data", Integer.to_string(i), Integer.to_string(j)]
        node = TreePath.new(segments) |> Node.new("node_#{k}")
        {Node.path(node), node}
      end

    map_size(m) |> IO.puts()
  end

  def bench_ets_set do
    t = :ets.new(:ptree, [:named_table])

    start = DateTime.utc_now()

    for i <- 1..100, j <- 1..100, k <- 1..20 do
      segments = ["data", Integer.to_string(i), Integer.to_string(j)]
      node = TreePath.new(segments) |> Node.new("node_#{k}")
      :ets.insert(t, {Node.path(node), node})
    end

    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

    :ets.tab2list(t) |> length() |> IO.puts()
  end
end
