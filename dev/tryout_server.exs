import DataTree.{Node, TreePath}

alias DataTree.{Node, TreePath}

DataTreeServer.start_link(name: :ptree)

# -----------

{:ok, data} = DataTreeServer.insert(:ptree, ~n"data")
{:ok, local} = DataTreeServer.insert(:ptree, ~n"data.local")

timestamp = DateTime.utc_now() |> DateTime.to_unix()

n = Node.new(~p"data.local", "ticks", :int32, timestamp, :milliseconds)
{:ok, ticks} = DataTreeServer.insert(:ptree, n)

IO.inspect(data)
IO.inspect(local)
IO.inspect(ticks)

IO.puts(ticks.value)

Enum.map(
  18..28,
  fn i ->
    name = "param" <> Integer.to_string(i)
    DataTreeServer.insert(:ptree, ~n"data.#{name}")
  end
)

DataTreeServer.lookup(:ptree, ~p"data.param23") |> IO.inspect()

# -----------

p = TreePath.new(["data", "local", "objects"])
IO.inspect(p)

TreePath.parent(p) |> IO.puts()
TreePath.append(p, "myClock") |> IO.puts()
TreePath.append(p, TreePath.new(["remote", "peer", "dark_star"])) |> IO.puts()
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

DataTreeServer.insert(:ptree, ~n"data.local.cluster")
DataTreeServer.insert(:ptree, ~n"data.local.cluster.node0")
DataTreeServer.insert(:ptree, ~n"data.local.cluster.node0.state")
DataTreeServer.insert(:ptree, ~n"data.local.cluster.node1")
DataTreeServer.insert(:ptree, ~n"data.local.cluster.node1.state")
DataTreeServer.insert(:ptree, ~n"data.local.cluster.mode")

sub = DataTreeServer.subtree(:ptree, ~p"data.local")
sub |> IO.inspect()
length(sub) |> IO.puts()
