import DataTree.{Node, TreePath}

alias DataTree.NodeTable

NodeTable.new(:vt0, :public)
NodeTable.new(:vt1, :public)
NodeTable.new(:vt2, :public)
NodeTable.new(:vt3, :public)
NodeTable.new(:vt4, :public)
NodeTable.new(:vt5, :public)

for i <- 1..10, j <- 1..10, k <- 1..20 do
  NodeTable.insert(:vt0, ~n"data.#{i}.#{j}.node_#{k}")
end

for i <- 1..10000, k <- 1..20 do
  NodeTable.insert(:vt1, ~n"data.#{i}.node_#{k}")
end

for i <- 1..100, j <- 1..100, k <- 1..20 do
  NodeTable.insert(:vt2, ~n"data.#{i}.#{j}.node_#{k}")
end

for i <- 1..10, j <- 1..10, k <- 1..10, l <- 1..10, m <- 1..10, n <- 1..20 do
  NodeTable.insert(:vt3, ~n"data.#{i}.#{j}.#{k}.#{l}.#{m}.node_#{n}")
end

for i <- 1..1000, j <- 1..1000, k <- 1..10 do
  NodeTable.insert(:vt4, ~n"data.#{i}.#{j}.node_#{k}")
end

Benchee.run(
  %{
    "update_value" => fn {table, path} -> NodeTable.update_value(table, path, 12345) end
  },
  inputs: %{
    "small" => {:vt0, ~p"data.3.4.node_11"},
    "medium_wide" => {:vt1, ~p"data.2342.node_11"},
    "medium_balanced" => {:vt2, ~p"data.23.42.node_11"},
    "medium_deep" => {:vt3, ~p"data.2.3.4.2.6.node_11"},
    "large" => {:vt4, ~p"data.2342.4223.node_8"}
  }
)
