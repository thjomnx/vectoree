import DataTree.TreePath

alias DataTree.Node

tree_small =
  for i <- 1..10, j <- 1..10, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new()}
  end

tree_medium =
  for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new()}
  end

tree_large =
  for i <- 1..1000, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Node.new()}
  end

Benchee.run(
  %{
    "update_value" => fn {tree, path} -> DataTree.update_value(tree, path, 12345) end
  },
  inputs: %{
    "small" => {tree_small, ~p"data.3.4.node_11"},
    "medium" => {tree_medium, ~p"data.23.42.node_11"},
    "large" => {tree_large, ~p"data.2323.42.node_11"}
  }
)
