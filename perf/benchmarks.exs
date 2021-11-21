import DataTree.{Node, TreePath}

DataTree.new(name: :vt0, visibility: :public)
DataTree.new(name: :vt1, visibility: :public)
DataTree.new(name: :vt2, visibility: :public)
DataTree.new(name: :vt3, visibility: :public)
DataTree.new(name: :vt4, visibility: :public)
DataTree.new(name: :vt5, visibility: :public)

for i <- 1..10, j <- 1..10, k <- 1..20 do
  DataTree.insert(:vt0, ~n"data.#{i}.#{j}.node_#{k}")
end

for i <- 1..10000, k <- 1..20 do
  DataTree.insert(:vt1, ~n"data.#{i}.node_#{k}")
end

for i <- 1..100, j <- 1..100, k <- 1..20 do
  DataTree.insert(:vt2, ~n"data.#{i}.#{j}.node_#{k}")
end

for i <- 1..10, j <- 1..10, k <- 1..10, l <- 1..10, m <- 1..10, n <- 1..20 do
  DataTree.insert(:vt3, ~n"data.#{i}.#{j}.#{k}.#{l}.#{m}.node_#{n}")
end

for i <- 1..1000, j <- 1..1000, k <- 1..10 do
  DataTree.insert(:vt4, ~n"data.#{i}.#{j}.node_#{k}")
end

Benchee.run(
  %{
    "update_value" => fn {table, path} -> DataTree.update_value(table, path, 12345) end
  },
  inputs: %{
    "small" => {:vt0, ~p"data.3.4.node_11"},
    "medium_wide" => {:vt1, ~p"data.2342.node_11"},
    "medium_balanced" => {:vt2, ~p"data.23.42.node_11"},
    "medium_deep" => {:vt3, ~p"data.2.3.4.2.6.node_11"},
    "large" => {:vt4, ~p"data.2342.4223.node_8"}
  }
)
