defmodule Vectoree.TreeTest do
  use ExUnit.Case, async: true

  alias Vectoree.{Tree, TreePath}

  @moduletag :capture_log

  doctest Tree

  setup do
    path = TreePath.new(["a", "b", "c", "d"])

    nodes = for i <- 0..9, into: %{}, do: {TreePath.append(path, "n#{i}"), :payload}
    tree = Tree.normalize(nodes)

    {:ok, nodes: nodes, tree: tree}
  end

  test "module exists" do
    assert is_list(Tree.module_info())
  end

  test "denormalize" do
    tree =
      %{
        TreePath.new(["a", "b", "c", "d0"]) => :payload,
        TreePath.new(["a", "b", "c", "d1"]) => :payload,
        TreePath.new(["a", "b", "c", "d2"]) => :payload,
        TreePath.new(["a", "b", "e"]) => :payload,
        TreePath.new(["a", "b", "e", "f"]) => :payload,
        TreePath.new(["a", "b", "g", "h", "i0"]) => :payload,
        TreePath.new(["a", "b", "g", "h", "i1"]) => nil
      }
      |> Tree.normalize()

    assert map_size(tree) == 12

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 11

    tree = Map.delete(tree, TreePath.new(["a", "b", "g", "h", "i0"]))
    assert map_size(tree) == 10

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 8

    tree = Map.delete(tree, TreePath.new(["a", "b", "e", "f"]))
    assert map_size(tree) == 7

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 7

    tree = Map.delete(tree, TreePath.new(["a", "b", "e"]))
    assert map_size(tree) == 6

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 6

    tree = Map.delete(tree, TreePath.new(["a", "b", "c", "d1"]))
    assert map_size(tree) == 5

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 5

    tree = Map.delete(tree, TreePath.new(["a", "b", "c", "d0"]))
    tree = Map.delete(tree, TreePath.new(["a", "b", "c", "d2"]))
    assert map_size(tree) == 3

    tree = Tree.denormalize(tree)
    assert map_size(tree) == 0
  end

  test "size", context do
    assert map_size(context[:nodes]) == 10
    assert map_size(context[:tree]) == 14
  end

  test "payload", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    :error = Tree.payload(tree, TreePath.new([]))

    {:ok, nil} = Tree.payload(tree, TreePath.root(path))
    {:ok, nil} = Tree.payload(tree, path)
    {:ok, :payload} = Tree.payload(tree, TreePath.append(path, "n3"))
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

  test "delete", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = Tree.delete(tree, TreePath.append(path, "n3"))

    :error = Tree.payload(tree, TreePath.append(path, "n3"))
    assert map_size(tree) == 13

    tree = Tree.delete(tree, path)

    :error = Tree.payload(tree, path)
    assert map_size(tree) == 0

    # tree = Tree.delete(tree, TreePath.root(path))

    # assert map_size(tree) == 0
  end

  test "delete with empty path", context do
    tree = context[:tree]

    tree = Tree.delete(tree, TreePath.new([]))
    assert map_size(tree) == 0
  end

  test "delete with non-existing path", context do
    tree = context[:tree]

    tree = Tree.delete(tree, TreePath.new(["x"]))
    assert map_size(tree) == 14
  end
end
