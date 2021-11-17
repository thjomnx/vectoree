import DataTree.{Node, TreePath}

DataTree.new(name: :vt0, visibility: :public)

for i <- 1..100, j <- 1..100, k <- 1..20 do
  DataTree.insert(:vt0, ~n"data.#{i}.#{j}.node_#{k}")
end

path = ~p"data.23.42.node_11"

Benchee.run(
  %{
    "update_value" => fn -> DataTree.update_value(:vt0, path, 12345) end
  }
)
