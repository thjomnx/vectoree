defmodule Vectoree.TreeTest do
  use ExUnit.Case, async: true

  alias Vectoree.{Node, Tree, TreePath}

  @moduletag :capture_log

  doctest Tree

  setup do
    path = TreePath.new(["a", "b", "c", "d"])

    nodes = for i <- 0..9, into: %{}, do: {TreePath.append(path, "n#{i}"), Node.new()}
    tree = Tree.normalize(nodes)

    {:ok, nodes: nodes, tree: tree}
  end

  test "module exists" do
    assert is_list(Tree.module_info())
  end

  test "size", context do
    assert map_size(context[:nodes]) == 10
    assert map_size(context[:tree]) == 14
  end

  test "node", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    :error = Tree.node(tree, TreePath.new([]))

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.root(path))
    assert n != nil

    {:ok, %Node{} = n} = Tree.node(tree, path)
    assert n != nil

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.append(path, "n3"))
    assert n != nil
  end

  test "children", context do
    tree = context[:tree]

    children = Tree.children(tree, TreePath.new([]))
    assert map_size(children) == 1

    children = Tree.children(tree, TreePath.new(["a"]))
    assert map_size(children) == 2

    children = Tree.children(tree, TreePath.new(["a", "b"]))
    assert map_size(children) == 2

    children = Tree.children(tree, TreePath.new(["a", "b", "c"]))
    assert map_size(children) == 2

    children = Tree.children(tree, TreePath.new(["a", "b", "c", "d"]))
    assert map_size(children) == 11

    children = Tree.children(tree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert map_size(children) == 1

    children = Tree.children(tree, TreePath.new(["invalid"]))
    assert map_size(children) == 0
  end

  test "subtree", context do
    tree = context[:tree]

    subtree = Tree.subtree(tree, TreePath.new([]))
    assert map_size(subtree) == 14

    subtree = Tree.subtree(tree, TreePath.new(["a", "b"]))
    assert map_size(subtree) == 13

    subtree = Tree.subtree(tree, TreePath.new(["a", "b", "c"]))
    assert map_size(subtree) == 12

    subtree = Tree.subtree(tree, TreePath.new(["a", "b", "c", "d"]))
    assert map_size(subtree) == 11

    subtree = Tree.subtree(tree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert map_size(subtree) == 1

    subtree = Tree.subtree(tree, TreePath.new(["invalid"]))
    assert map_size(subtree) == 0
  end

  test "update_value on subtreetree", context do
    tree = context[:tree]

    tree = Tree.update_value(tree, "foo")

    Map.values(tree) |> Enum.each(fn node -> assert node.value == "foo" end)
  end

  test "update_value for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = Tree.update_value(tree, path, "bar")

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.root(path))
    assert n.value == :empty

    {:ok, %Node{} = n} = Tree.node(tree, path)
    assert n.value == "bar"

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.append(path, "n3"))
    assert n.value == :empty
  end

  test "update_status on subtree", context do
    tree = context[:tree]

    tree = Tree.update_status(tree, 128)

    Map.values(tree) |> Enum.each(fn node -> assert node.status == 128 end)
  end

  test "update_status for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = Tree.update_status(tree, path, 128)

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.root(path))
    assert n.status == 0

    {:ok, %Node{} = n} = Tree.node(tree, path)
    assert n.status == 128

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.append(path, "n3"))
    assert n.status == 0
  end

  test "update_time_modified on subtree", context do
    tree = context[:tree]
    time = System.system_time()

    tree = Tree.update_time_modified(tree, time)

    Map.values(tree) |> Enum.each(fn node -> assert node.modified == time end)
  end

  test "update_time_modified for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])
    time = System.system_time()

    tree = Tree.update_time_modified(tree, path, time)

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.root(path))
    assert n.modified == 0

    {:ok, %Node{} = n} = Tree.node(tree, path)
    assert n.modified == time

    {:ok, %Node{} = n} = Tree.node(tree, TreePath.append(path, "n3"))
    assert n.modified == 0
  end

  test "delete", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = Tree.delete(tree, TreePath.append(path, "n3"))

    :error = Tree.node(tree, TreePath.append(path, "n3"))
    assert map_size(tree) == 13

    tree = Tree.delete(tree, path)

    :error = Tree.node(tree, path)
    assert map_size(tree) == 3

    tree = Tree.delete(tree, TreePath.root(path))

    assert map_size(tree) == 0
  end

  test "delete with empty path", context do
    tree = context[:tree]

    tree = Tree.delete(tree, TreePath.new([]))
    assert map_size(tree) == 0
  end
end
