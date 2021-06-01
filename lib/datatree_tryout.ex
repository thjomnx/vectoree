defmodule DataTree.Tryout do
  def test do
    DataTree.start_link(name: :mtree)

    DataTree.lookup(:mtree, "data")

    DataTree.put(:mtree, "data", DataTree.Node.new("data"))
    {:ok, n} = DataTree.lookup(:mtree, "data")

    ts = DateTime.utc_now() |> DateTime.to_unix()
    l = DataTree.Leaf.new("ticks", :int32, ts, :milliseconds)
    n = DataTree.Node.add_leaf(n, l)

    DataTree.put(:mtree, "data", n)
    {:ok, last} = DataTree.lookup(:mtree, "data")

    last
  end
end
