import DataTree.{Node, TreePath}

DataTree.new(name: :ptree)

IO.puts("DataTree.populate")

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

IO.puts("DataTree.update_many")

path = ~p"data.23.42.node_11"
start = DateTime.utc_now()

for i <- 1..10_000_000 do
  DataTree.update_value(:ptree, path, i)
end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
