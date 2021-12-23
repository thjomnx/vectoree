import DataTree.{Node, TreePath}

{:ok, _} = DataTree.start_link(name: :vt)

IO.puts("Tree population")

start = DateTime.utc_now()

for i <- 1..100, j <- 1..100, k <- 1..20 do
  DataTree.insert(:vt, ~n"data.#{i}.#{j}.node_#{k}")
end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()

IO.puts("Subtree computation")

start = DateTime.utc_now()

case DataTree.subtree(:vt, ~p"data") do
  {:ok, sub} ->
    DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
    length(sub) |> IO.puts()

  {:error, reason} ->
    IO.puts(reason)
end

IO.puts("Tree node updating")

path = ~p"data.23.42.node_11"
start = DateTime.utc_now()

for i <- 1..10_000_000 do
  DataTree.update_value(:vt, path, i)
end

DateTime.utc_now() |> DateTime.diff(start, :millisecond) |> IO.puts()
