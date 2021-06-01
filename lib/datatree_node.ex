defmodule DataTree.Node do
  alias DataTree.{TimeInfo, Status}

  defstruct [:name, leaves: [], time: TimeInfo.new, status: Status.new]

  def new(name) do
    %DataTree.Node{name: name}
  end

  def add_leaf(node = %DataTree.Node{}, leaf = %DataTree.Leaf{}) do
    new_leaves = List.insert_at(node.leaves, 0, leaf)
    %DataTree.Node{node | leaves: new_leaves}
  end
end
