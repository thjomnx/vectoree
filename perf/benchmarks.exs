import DataTree.TreePath

alias DataTree.Node

tree0 =
  for i <- 1..10, j <- 1..10, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new()}
  end

tree1 =
  for i <- 1..10000, k <- 1..20, into: %{} do
    {~p"data.#{i}.node_#{k}", Node.new()}
  end

tree2 =
  for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new()}
  end

tree3 =
  for i <- 1..10, j <- 1..10, k <- 1..10, l <- 1..10, m <- 1..10, n <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.#{k}.#{l}.#{m}.node_#{n}", Node.new()}
  end

Benchee.run(
  %{
    "update_value" => fn {tree, path} -> DataTree.update_value(tree, path, 12345) end
  },
  inputs: %{
    "small" => {tree0, ~p"data.3.4.node_11"},
    "medium_wide" => {tree1, ~p"data.2342.node_11"},
    "medium_balanced" => {tree2, ~p"data.23.42.node_11"},
    "medium_deep" => {tree3, ~p"data.2.3.4.2.6.node_11"}
  }
)
