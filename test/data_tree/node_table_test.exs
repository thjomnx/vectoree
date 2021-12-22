defmodule DataTree.NodeTableTest do
  use ExUnit.Case

  alias DataTree.{NodeTable, Node, TreePath}

  @moduletag :capture_log

  doctest NodeTable

  test "module exists" do
    assert is_list(NodeTable.module_info())
  end

  test "new" do
    assert {:ok, :testtree} == NodeTable.new(:testtree)
  end

  test "children" do
    NodeTable.new(:testtree)
    tp = TreePath.new(["a", "b", "c", "d"])

    for i <- 0..9 do
      NodeTable.insert(:testtree, Node.new(tp, "n#{i}"))
    end

    {:ok, children} = NodeTable.children(:testtree, TreePath.new(["a"]))
    assert length(children) == 2

    {:ok, children} = NodeTable.children(:testtree, TreePath.new(["a", "b"]))
    assert length(children) == 2

    {:ok, children} = NodeTable.children(:testtree, TreePath.new(["a", "b", "c"]))
    assert length(children) == 2

    {:ok, children} = NodeTable.children(:testtree, TreePath.new(["a", "b", "c", "d"]))
    assert length(children) == 11

    {:ok, children} = NodeTable.children(:testtree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert length(children) == 1

    {:error, _reason} = NodeTable.children(:testtree, TreePath.new(["invalid"]))
  end

  test "subtree" do
    NodeTable.new(:testtree)
    tp = TreePath.new(["a", "b", "c", "d"])

    for i <- 0..9 do
      NodeTable.insert(:testtree, Node.new(tp, "n#{i}"))
    end

    {:ok, subtree} = NodeTable.subtree(:testtree, TreePath.new(["a"]))
    assert length(subtree) == 14

    {:ok, subtree} = NodeTable.subtree(:testtree, TreePath.new(["a", "b"]))
    assert length(subtree) == 13

    {:ok, subtree} = NodeTable.subtree(:testtree, TreePath.new(["a", "b", "c"]))
    assert length(subtree) == 12

    {:ok, subtree} = NodeTable.subtree(:testtree, TreePath.new(["a", "b", "c", "d"]))
    assert length(subtree) == 11

    {:ok, subtree} = NodeTable.subtree(:testtree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert length(subtree) == 1

    {:error, _reason} = NodeTable.subtree(:testtree, TreePath.new(["invalid"]))
  end

  test "insert" do
    NodeTable.new(:testtree)

    name = "d"
    parent = TreePath.new(["a", "b", "c"])
    {:ok, node} = NodeTable.insert(:testtree, Node.new(parent, name))

    assert node.parent == parent
    assert node.name == name
    assert NodeTable.size(:testtree) == 5
  end

  test "delete" do
    NodeTable.new(:testtree)

    name = "d"
    parent = TreePath.new(["a", "b", "c"])
    {:ok, _node} = NodeTable.insert(:testtree, Node.new(parent, name))

    :ok = NodeTable.delete(:testtree, TreePath.new(["a", "b", "c", "d"]))

    {:ok, _node} = NodeTable.node(:testtree, TreePath.new(["a"]))
    {:ok, _node} = NodeTable.node(:testtree, TreePath.new(["a", "b"]))
    {:ok, _node} = NodeTable.node(:testtree, TreePath.new(["a", "b", "c"]))
    {:error, _msg} = NodeTable.node(:testtree, TreePath.new(["a", "b", "c", "d"]))

    :ok = NodeTable.delete(:testtree, TreePath.new(["a", "b"]))

    {:ok, _node} = NodeTable.node(:testtree, TreePath.new(["a"]))
    {:error, _msg} = NodeTable.node(:testtree, TreePath.new(["a", "b"]))
    {:error, _msg} = NodeTable.node(:testtree, TreePath.new(["a", "b", "c"]))
    {:error, _msg} = NodeTable.node(:testtree, TreePath.new(["a", "b", "c", "d"]))
  end
end
