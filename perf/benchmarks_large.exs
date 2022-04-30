import DataTree.TreePath

alias DataTree.Node

tree =
  for i <- 1..10,
      j <- 1..10,
      k <- 1..10,
      l <- 1..10,
      m <- 1..10,
      n <- 1..10,
      o <- 1..10,
      p <- 1..2,
      into: %{} do
    {~p"data.#{i}.#{j}.#{k}.#{l}.#{m}.#{n}.#{o}.node_#{p}", Node.new()}
  end

Benchee.run(
  %{
    "update_value" => fn {tree, path} -> DataTree.update_value(tree, path, 12345) end
  },
  inputs: %{
    "large_deep" => {tree, ~p"data.2.3.4.5.6.7.8.node_2"}
  }
)
