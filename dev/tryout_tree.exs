import Vectoree.TreePath

alias Vectoree.Tree

defmodule Stopwatch do
  def inspect(func) do
    start = DateTime.utc_now()
    result = func.()
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
    result
  end
end

defmodule Payload do
  defstruct [
    :type,
    :value,
    :unit,
    status: 0,
    modified: 0
  ]

  def new(
        type \\ :none,
        value \\ :empty,
        unit \\ :none,
        status \\ 0,
        modified \\ 0
      ) do
    %Payload{
      type: type,
      value: value,
      unit: unit,
      status: status,
      modified: modified
    }
  end

  def format(%Payload{type: t, value: v, unit: u, status: s, modified: m}) do
    "#{v} [#{u}] (#{t}/#{s}/#{m})"
  end

  def format(nil) do
    "nil"
  end
end

IO.puts("==> Tree.populate")
start = DateTime.utc_now()

map =
  for i <- 1..100, j <- 1..100, k <- 1..200, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Payload.new(:int32, System.system_time(), :nanosecond)}
  end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.inspect(label: "Time [ms]")
map_size(map) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.normalize")
map = Stopwatch.inspect(fn -> Tree.normalize(map) end)
map_size(map) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.denormalize")
map = Stopwatch.inspect(fn -> Tree.denormalize(map) end)
map_size(map) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.payload")
Stopwatch.inspect(fn -> Tree.payload(map, ~p"data.23.42.node_11") |> IO.inspect() end)

# --------------------

IO.puts("==> Tree.children")
chln = Stopwatch.inspect(fn -> Tree.children(map, ~p"data.23.42") end)
map_size(chln) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.subtree")
sub = Stopwatch.inspect(fn -> Tree.subtree(map, ~p"data") end)
map_size(sub) |> IO.inspect(label: "Size")

# --------------------

IO.puts("==> Tree.delete")
del = Stopwatch.inspect(fn -> Tree.delete(map, ~p"data") end)
map_size(del) |> IO.inspect(label: "Size")
