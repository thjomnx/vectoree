import DataTree.TreePath

alias DataTree.Node

IO.puts("==> DataTree.populate")
start = DateTime.utc_now()

map =
  for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new(:int32, System.system_time(), :nanoseconds)}
  end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
IO.puts("==> DataTree.subtree")
start = DateTime.utc_now()

sub = DataTree.subtree(map, ~p"data")

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(sub) |> IO.inspect(label: "Size")
IO.puts("==> DataTree.node")
start = DateTime.utc_now()

DataTree.node(map, ~p"data.23.42.node_11") |> IO.inspect(label: "PathNode tuple")

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
IO.puts("==> DataTree.normalize")
start = DateTime.utc_now()

norm = DataTree.normalize(map)

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(norm) |> IO.inspect(label: "Size")

IO.puts("==> DataTree.update")
start = DateTime.utc_now()

up = DataTree.update_status(map, 128)

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(up) |> IO.inspect(label: "Size")
{_p, v} = DataTree.node(up, ~p"data.23.42.node_11")
IO.inspect(v.status, label: "Updated tuple status")

IO.puts("==> DataTree.update_single")

path = ~p"data.23.42.node_11"
start = DateTime.utc_now()

up = DataTree.update_status(up, path, -127)

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(up) |> IO.inspect(label: "Size")
{_p, v} = DataTree.node(up, ~p"data.23.42.node_11")
IO.inspect(v.status, label: "Updated single tuple status")
IO.inspect(v.modified, label: "Updated single tuple modified")
{_p, v} = DataTree.node(up, ~p"data.23.42.node_12")
IO.inspect(v.status, label: "Updated other tuple status")
IO.inspect(v.modified, label: "Updated other tuple modified")
