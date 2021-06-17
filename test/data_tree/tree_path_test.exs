defmodule DataTree.TreePathTest do
  use ExUnit.Case

  alias DataTree.TreePath

  @moduletag :capture_log

  doctest TreePath

  test "module exists" do
    assert is_list(TreePath.module_info())
  end

  test "new via binary" do
    assert is_struct(TreePath.new("a"), TreePath)
    assert TreePath.new("a.b.c") |> to_string == "a_2eb_2ec"
  end

  test "new via tuple" do
    assert is_struct(TreePath.new({"a", "b", "c"}), TreePath)
  end

  test "new via list" do
    assert is_struct(TreePath.new(["a", "b", "c"]), TreePath)
  end

  test "root" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.root(p) == TreePath.new("a")
  end

  test "parent" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.parent(p) == TreePath.new(["a", "b"])
  end

  test "base" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.base(p) == TreePath.new("c")
  end

  test "basename" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.basename(p) == "c"
  end

  test "sibling" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.sibling(p, "d") == TreePath.new(["a", "b", "d"])
  end

  test "append" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.append(p, "d") == TreePath.new(["a", "b", "c", "d"])
    assert TreePath.append(p, {"d", "e"}) == TreePath.new(["a", "b", "c", "d", "e"])
    assert TreePath.append(p, ["d", "e"]) == TreePath.new(["a", "b", "c", "d", "e"])
  end

  test "starts_with?" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.starts_with?(p, TreePath.parent(p))
    assert TreePath.starts_with?(p, TreePath.new("a"))
    refute TreePath.starts_with?(p, TreePath.new("b"))
    refute TreePath.starts_with?(p, TreePath.new("c"))
    refute TreePath.starts_with?(p, TreePath.new({"a", "d"}))
    refute TreePath.starts_with?(p, TreePath.append(p, "x"))
  end

  test "ends_with?" do
    p = TreePath.new(["a", "b", "c"])

    refute TreePath.ends_with?(p, TreePath.parent(p))
    refute TreePath.ends_with?(p, TreePath.new("a"))
    refute TreePath.ends_with?(p, TreePath.new("b"))
    assert TreePath.ends_with?(p, TreePath.new("c"))
    assert TreePath.ends_with?(p, TreePath.new({"b", "c"}))
    refute TreePath.ends_with?(p, TreePath.append(p, "x"))
  end
end
