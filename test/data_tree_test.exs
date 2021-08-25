defmodule DataTreeTest do
  use ExUnit.Case

  alias DataTree.{Node, TreePath}

  doctest DataTree

  test "module exists" do
    assert is_list(DataTree.module_info())
  end

  test "new" do
    assert {:ok, :testtree} == DataTree.new(name: :testtree)
  end

  test "insert" do
    DataTree.new(name: :testtree)

    name = "d"
    parent = TreePath.new(["a", "b", "c"])
    {:ok, node} = DataTree.insert(:testtree, Node.new(parent, name))

    assert node.parent_path == parent
    assert node.name == name
    assert DataTree.size(:testtree) == 5
  end
end
