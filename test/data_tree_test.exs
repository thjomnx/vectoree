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

  test "subtree" do
    DataTree.new(name: :testtree)
    tp = TreePath.new(["a", "b", "c", "d"])

    for i <- 0..9 do
      DataTree.insert(:testtree, Node.new(tp, "n#{i}"))
    end

    {:ok, subtree} = DataTree.subtree(:testtree, TreePath.new(["a"]))
    assert length(subtree) == 14

    {:ok, subtree} = DataTree.subtree(:testtree, TreePath.new(["a", "b"]))
    assert length(subtree) == 13

    {:ok, subtree} = DataTree.subtree(:testtree, TreePath.new(["a", "b", "c"]))
    assert length(subtree) == 12

    {:ok, subtree} = DataTree.subtree(:testtree, TreePath.new(["a", "b", "c", "d"]))
    assert length(subtree) == 11

    {:ok, subtree} = DataTree.subtree(:testtree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert length(subtree) == 1

    {:error, _reason} = DataTree.subtree(:testtree, TreePath.new(["invalid"]))
  end

  test "children" do
    DataTree.new(name: :testtree)
    tp = TreePath.new(["a", "b", "c", "d"])

    for i <- 0..9 do
      DataTree.insert(:testtree, Node.new(tp, "n#{i}"))
    end

    {:ok, children} = DataTree.children(:testtree, TreePath.new(["a"]))
    assert length(children) == 2

    {:ok, children} = DataTree.children(:testtree, TreePath.new(["a", "b"]))
    assert length(children) == 2

    {:ok, children} = DataTree.children(:testtree, TreePath.new(["a", "b", "c"]))
    assert length(children) == 2

    {:ok, children} = DataTree.children(:testtree, TreePath.new(["a", "b", "c", "d"]))
    assert length(children) == 11

    {:ok, children} = DataTree.children(:testtree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert length(children) == 1

    {:error, _reason} = DataTree.children(:testtree, TreePath.new(["invalid"]))
  end

  test "insert" do
    DataTree.new(name: :testtree)

    name = "d"
    parent = TreePath.new(["a", "b", "c"])
    {:ok, node} = DataTree.insert(:testtree, Node.new(parent, name))

    assert node.parent == parent
    assert node.name == name
    assert DataTree.size(:testtree) == 5
  end
end
