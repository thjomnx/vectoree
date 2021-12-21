import DataTree.{Node, TreePath}

alias DataTree.NodeTable

NodeTable.new(name: :ptree)

IO.puts("NodeTable.populate")

start = DateTime.utc_now()

for i <- 1..100, j <- 1..100, k <- 1..20 do
  NodeTable.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

IO.puts("NodeTable.subtree")

start = DateTime.utc_now()

case NodeTable.subtree(:ptree, ~p"data") do
  {:ok, sub} ->
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
    length(sub) |> IO.puts()

  {:error, reason} ->
    IO.puts(reason)
end

IO.puts("NodeTable.update_many")

path = ~p"data.23.42.node_11"
start = DateTime.utc_now()

for i <- 1..10_000_000 do
  NodeTable.update_value(:ptree, path, i)
end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
