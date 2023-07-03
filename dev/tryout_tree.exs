import Vectoree.TreePath

alias Vectoree.{Node, Tree}

defmodule Stopwatch do
  def inspect(func) do
    start = DateTime.utc_now()
    result = func.()
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
    result
  end
end

IO.puts("==> Tree.populate")
start = DateTime.utc_now()

map =
  for i <- 1..100, j <- 1..100, k <- 1..200, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new(:int32, System.system_time(), :nanosecond)}
  end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(map) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.normalize")
map = Stopwatch.inspect(fn -> Tree.normalize(map) end)
map_size(map) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.node")
Stopwatch.inspect(fn -> Tree.node(map, ~p"data.23.42.node_11") |> IO.inspect() end)

# --------------------

IO.puts("==> Tree.children")
chln = Stopwatch.inspect(fn -> Tree.children(map, ~p"data.23.42") end)
map_size(chln) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.subtree")
sub = Stopwatch.inspect(fn -> Tree.subtree(map, ~p"data") end)
map_size(sub) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.update_status")
up = Stopwatch.inspect(fn -> Tree.update_status(map, 128) end)
map_size(up) |> IO.inspect(label: "Size")
{_p, v} = Tree.node(up, ~p"data.23.42.node_11")
IO.inspect(v.status, label: "Updated tuple status")

# --------------------

IO.puts("==> Tree.update_status (single)")
path = ~p"data.23.42.node_11"
up = Stopwatch.inspect(fn -> Tree.update_status(up, path, -127) end)
map_size(up) |> IO.inspect(label: "Size")
{_p, v} = Tree.node(up, ~p"data.23.42.node_11")
IO.inspect(v.status, label: "Updated single tuple status")
IO.inspect(v.modified, label: "Updated single tuple modified")
{_p, v} = Tree.node(up, ~p"data.23.42.node_12")
IO.inspect(v.status, label: "Updated other tuple status")
IO.inspect(v.modified, label: "Updated other tuple modified")

# --------------------

IO.puts("==> Tree.delete")
del = Stopwatch.inspect(fn -> Tree.delete(map, ~p"data") end)
map_size(del) |> IO.inspect(label: "Size")
