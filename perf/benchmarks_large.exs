import DataTree.{Node, TreePath}

alias DataTree.NodeTable

NodeTable.new(:vt0, :public)

for i <- 1..10,
    j <- 1..10,
    k <- 1..10,
    l <- 1..10,
    m <- 1..10,
    n <- 1..10,
    o <- 1..10,
    p <- 1..2 do
      NodeTable.insert(:vt0, ~n"data.#{i}.#{j}.#{k}.#{l}.#{m}.#{n}.#{o}.node_#{p}")
end

Benchee.run(
  %{
    "update_value" => fn {table, path} -> NodeTable.update_value(table, path, 12345) end
  },
  inputs: %{
    "large_deep" => {:vt0, ~p"data.2.3.4.5.6.7.8.node_2"}
  }
)
