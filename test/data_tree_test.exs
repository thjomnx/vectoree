defmodule DataTree.DataTreeTest do
  use ExUnit.Case, async: true

  alias DataTree.{Node, TreePath}

  @moduletag :capture_log

  doctest DataTree

  setup do
    path = TreePath.new(["a", "b", "c", "d"])

    nodes = for i <- 0..9, into: %{}, do: {TreePath.append(path, "n#{i}"), Node.new()}
    tree = DataTree.normalize(nodes)

    {:ok, nodes: nodes, tree: tree}
  end

  test "module exists" do
    assert is_list(DataTree.module_info())
  end

  test "size", context do
    assert map_size(context[:nodes]) == 10
    assert map_size(context[:tree]) == 14
  end

  test "node", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    {p, n} = DataTree.node(tree, TreePath.new([]))
    assert p == TreePath.new([])
    assert n == nil

    {p, n} = DataTree.node(tree, TreePath.root(path))
    assert p == TreePath.root(path)
    assert n != nil

    {p, n} = DataTree.node(tree, path)
    assert p == path
    assert n != nil

    {p, n} = DataTree.node(tree, TreePath.append(path, "n3"))
    assert p == TreePath.append(path, "n3")
    assert n != nil
  end

  test "subtree", context do
    tree = context[:tree]

    sub = DataTree.subtree(tree, TreePath.new([]))
    assert map_size(sub) == 14

    sub = DataTree.subtree(tree, TreePath.new(["a", "b"]))
    assert map_size(sub) == 13

    sub = DataTree.subtree(tree, TreePath.new(["a", "b", "c"]))
    assert map_size(sub) == 12

    sub = DataTree.subtree(tree, TreePath.new(["a", "b", "c", "d"]))
    assert map_size(sub) == 11

    sub = DataTree.subtree(tree, TreePath.new(["a", "b", "c", "d", "n5"]))
    assert map_size(sub) == 1

    sub = DataTree.subtree(tree, TreePath.new(["invalid"]))
    assert map_size(sub) == 0
  end

  test "update_value on subtree", context do
    tree = context[:tree]

    tree = DataTree.update_value(tree, "foo")

    Map.values(tree) |> Enum.each(fn node -> assert node.value == "foo" end)
  end

  test "update_value for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = DataTree.update_value(tree, path, "bar")

    {_, n} = DataTree.node(tree, TreePath.root(path))
    assert n.value == nil

    {_, n} = DataTree.node(tree, path)
    assert n.value == "bar"

    {_, n} = DataTree.node(tree, TreePath.append(path, "n3"))
    assert n.value == nil
  end

  test "update_status on subtree", context do
    tree = context[:tree]

    tree = DataTree.update_status(tree, 128)

    Map.values(tree) |> Enum.each(fn node -> assert node.status == 128 end)
  end

  test "update_status for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])

    tree = DataTree.update_status(tree, path, 128)

    {_, n} = DataTree.node(tree, TreePath.root(path))
    assert n.status == 0

    {_, n} = DataTree.node(tree, path)
    assert n.status == 128

    {_, n} = DataTree.node(tree, TreePath.append(path, "n3"))
    assert n.status == 0
  end

  test "update_time_modified on subtree", context do
    tree = context[:tree]
    time = System.system_time()

    tree = DataTree.update_time_modified(tree, time)

    Map.values(tree) |> Enum.each(fn node -> assert node.modified == time end)
  end

  test "update_time_modified for single path", context do
    tree = context[:tree]
    path = TreePath.new(["a", "b", "c", "d"])
    time = System.system_time()

    tree = DataTree.update_time_modified(tree, path, time)

    {_, n} = DataTree.node(tree, TreePath.root(path))
    assert n.modified == 0

    {_, n} = DataTree.node(tree, path)
    assert n.modified == time

    {_, n} = DataTree.node(tree, TreePath.append(path, "n3"))
    assert n.modified == 0
  end
end
