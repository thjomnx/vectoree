defmodule Tryout do
  use Application

  import DataTree.{Node, TreePath}

  alias DataTree.{Node, TreePath}

  def start(_type, _args) do
    run_proto()
    {:ok, self()}
  end

  def run_proto do
    DataTree.new(name: :ptree)

    # -----------

    {:ok, data} = DataTree.insert(:ptree, ~n"data")
    {:ok, local} = DataTree.insert(:ptree, ~n"data.local")

    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    n = Node.new(~p"data.local", "ticks", :int32, timestamp, :milliseconds)
    {:ok, ticks} = DataTree.insert(:ptree, n)

    IO.inspect(data)
    IO.inspect(local)
    IO.inspect(ticks)

    IO.puts(ticks.value)

    Enum.map(
      18..28,
      fn i ->
        name = "param" <> Integer.to_string(i)
        DataTree.insert(:ptree, ~n"data.#{name}")
      end
    )

    DataTree.node(:ptree, ~p"data.param23") |> IO.inspect()

    # -----------

    p = TreePath.new(["data", "local", "objects"])
    IO.inspect(p)

    TreePath.parent(p) |> IO.puts()
    TreePath.append(p, "myClock") |> IO.puts()
    TreePath.append(p, ~p"remote.peer.dark_star") |> IO.puts()
    TreePath.root(p) |> IO.puts()
    TreePath.new("data") |> TreePath.parent() |> IO.puts()
    TreePath.sibling(p, "monitors") |> IO.puts()
    TreePath.new(["", "data", "", "", "", "raw", "", "proj.x"]) |> IO.puts()

    IO.puts("-------------------------")

    TreePath.starts_with?(p, TreePath.parent(p)) |> IO.puts()
    TreePath.starts_with?(p, TreePath.new("data")) |> IO.puts()
    TreePath.starts_with?(p, TreePath.new("local")) |> IO.puts()
    TreePath.starts_with?(p, TreePath.new("objects")) |> IO.puts()
    TreePath.starts_with?(p, TreePath.new(["data", "remote"])) |> IO.puts()
    TreePath.starts_with?(p, TreePath.append(p, "blah")) |> IO.puts()

    IO.puts("-------------------------")

    TreePath.ends_with?(p, TreePath.parent(p)) |> IO.puts()
    TreePath.ends_with?(p, TreePath.new("data")) |> IO.puts()
    TreePath.ends_with?(p, TreePath.new("local")) |> IO.puts()
    TreePath.ends_with?(p, TreePath.new("objects")) |> IO.puts()
    TreePath.ends_with?(p, TreePath.new(["local", "objects"])) |> IO.puts()
    TreePath.ends_with?(p, TreePath.append(p, "blah")) |> IO.puts()

    IO.puts("-------------------------")

    DataTree.insert(:ptree, ~n"data.local.cluster")
    DataTree.insert(:ptree, ~n"data.local.cluster.node0")
    DataTree.insert(:ptree, ~n"data.local.cluster.node0.state")
    DataTree.insert(:ptree, ~n"data.local.cluster.node1")
    DataTree.insert(:ptree, ~n"data.local.cluster.node1.state")
    DataTree.insert(:ptree, ~n"data.local.cluster.mode")

    {:ok, sub} = DataTree.subtree(:ptree, ~p"data.local")
    sub |> IO.inspect()
    length(sub) |> IO.puts()
  end

  def ets_matching do
    # :ets.insert(t, {"a.b.c.x", "a.b.c", "x", :int32, 1287461765, :cochrane, 12418458145, 1826768276, false})
    # :ets.fun2ms(fn({abs_path, parent, name, type, value, unit, created, modified, valid}) when parent == "a.b.c" -> {abs_path, parent, name, type, value, unit, created, modified, valid} end)
    # :ets.select(t, m)
  end
end
