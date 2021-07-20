defmodule DataTree.TreePathTest do
  use ExUnit.Case

  import DataTree.TreePath

  alias DataTree.TreePath

  @moduletag :capture_log

  doctest TreePath

  test "module exists" do
    assert is_list(TreePath.module_info())
  end

  test "new via binary" do
    assert is_struct(TreePath.new(""), TreePath)
    assert is_struct(TreePath.new("a"), TreePath)
    assert TreePath.new("a.b.c") |> to_string == "a_2eb_2ec"
  end

  test "new via list" do
    assert is_struct(TreePath.new([]), TreePath)
    assert is_struct(TreePath.new(["a", "b", "c"]), TreePath)
  end

  test "sigil p" do
    assert is_struct(~p"", TreePath)
    assert is_struct(~p"a.b.c", TreePath)

    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    p = ~p"#{x}.#{y}.#{z}"
    assert is_struct(p, TreePath)
    # assert to_string(p) == "a.b.c.d.e"
  end

  test "level" do
    assert TreePath.level(~p"") == 0
    assert TreePath.level(~p"a") == 1
    assert TreePath.level(~p"a.b") == 2
    assert TreePath.level(~p"a.b.c") == 3
  end

  test "root" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.root(p) == TreePath.new("a")
    assert TreePath.root(~p"") == TreePath.new([])
  end

  test "rootname" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.rootname(p) == "a"
    assert TreePath.rootname(~p"") == ""
  end

  test "parent" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.parent(p) == TreePath.new(["a", "b"])
    assert TreePath.parent(~p"") == TreePath.new([])
  end

  test "base" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.base(p) == TreePath.new("c")
    assert TreePath.base(~p"") == TreePath.new([])
  end

  test "basename" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.basename(p) == "c"
    assert TreePath.basename(~p"") == ""
  end

  test "sibling" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.sibling(p, "d") == TreePath.new(["a", "b", "d"])
    assert TreePath.sibling(~p"", "d") == TreePath.new("d")
  end

  test "append" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.append(p, "d") == TreePath.new(["a", "b", "c", "d"])
    assert TreePath.append(p, ["d", "e"]) == TreePath.new(["a", "b", "c", "d", "e"])
    assert TreePath.append(~p"", "d") == TreePath.new("d")
  end

  test "starts_with?" do
    p = TreePath.new(["a", "b", "c"])

    assert TreePath.starts_with?(p, TreePath.parent(p))
    assert TreePath.starts_with?(p, TreePath.new("a"))
    refute TreePath.starts_with?(p, TreePath.new("b"))
    refute TreePath.starts_with?(p, TreePath.new("c"))
    refute TreePath.starts_with?(p, TreePath.append(p, "x"))
  end

  test "ends_with?" do
    p = TreePath.new(["a", "b", "c"])

    refute TreePath.ends_with?(p, TreePath.parent(p))
    refute TreePath.ends_with?(p, TreePath.new("a"))
    refute TreePath.ends_with?(p, TreePath.new("b"))
    assert TreePath.ends_with?(p, TreePath.new("c"))
    refute TreePath.ends_with?(p, TreePath.append(p, "x"))
  end
end
