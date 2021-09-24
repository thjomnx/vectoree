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
    assert TreePath.new("").segments == []
    assert TreePath.new("a").segments == ["a"]
    assert TreePath.new("  a.b.c  ").segments == ["  a.b.c  "]
  end

  test "new via list" do
    assert TreePath.new([]).segments == []
    assert TreePath.new(["a"]).segments == ["a"]
    assert TreePath.new(["a", "b", "c"]).segments == ["c", "b", "a"]
  end

  test "sigil p" do
    assert is_struct(~p"", TreePath)
    assert is_struct(~p"a.b.c", TreePath)

    assert ~p"  a.b.c  " == TreePath.new(["a", "b", "c"])

    # Test whitespace preservation
    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    p = ~p"m.#{x}.#{y}.#{z}.n"
    assert p == TreePath.new(["m", "  a.b", "  c  ", "d.e  ", "n"])

    # Test with atom interpolation
    p = ~p"abc.def.ghi.j#{:k}lm.nop.q#{:r}#{:s}t.uvw.xyz"
    assert p == TreePath.new(["abc", "def", "ghi", "jklm", "nop", "qrst", "uvw", "xyz"])

    # Test with variable interpolation
    kl = "kl"
    r = "r"
    s = "s"
    p = ~p"abc.def.ghi.j#{kl}m.nop.q#{r}#{s}t.uvw.xyz"
    assert p == TreePath.new(["abc", "def", "ghi", "jklm", "nop", "qrst", "uvw", "xyz"])
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
    assert TreePath.append(p, ~p"d.e") == TreePath.new(["a", "b", "c", "d", "e"])
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

  test "to_string" do
    assert TreePath.new("  a.b.c  ") |> to_string() == "  a_2eb_2ec  "
  end
end
