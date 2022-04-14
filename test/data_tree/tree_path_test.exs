defmodule DataTree.TreePathTest do
  use ExUnit.Case, async: true

  import DataTree.TreePath

  alias DataTree.TreePath

  @moduletag :capture_log

  doctest TreePath

  setup do
    {:ok, path: TreePath.new(["a", "b", "c"])}
  end

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
    assert ~p"" == TreePath.new([])
    assert ~p"a.b\nb.c" == TreePath.new(["a", "b\nb", "c"])

    # Test whitespace preservation
    assert ~p"  a . b  .  c " == TreePath.new(["  a ", " b  ", "  c "])

    # Test empty segment filtering (multi dots)
    assert ~p".. a...b  ..c.." == TreePath.new([" a", "b  ", "c"])

    # Test whitespace and dot preservation with variable interpolation
    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    p = ~p"m.#{x}. #{y}  .#{z}.n"
    assert p == TreePath.new(["m", "  a.b", "   c    ", "d.e  ", "n"])

    # Test with atom interpolation (single item)
    assert ~p"#{:x}" == TreePath.new(["x"])

    # Test with atom interpolation (mixed) including empty segment filtering (multi dots)
    p = ~p".ab\tc.def..ghi.j#{:k}l\nm.nop.q#{:r}#{:s}t...uvw.xyz..."
    assert p == TreePath.new(["ab\tc", "def", "ghi", "jkl\nm", "nop", "qrst", "uvw", "xyz"])

    # Test with variable interpolation including empty segment filtering (multi dots)
    zero = 0
    kl = "k\tl"
    r = "r"
    s = "s"
    sz = "ß"
    p = ~p".#{zero}.abc.def..ghi.j#{kl}m.nop.q#{r}#{s}t...uvw.xyz.#{sz}..."

    assert p ==
             TreePath.new(["0", "abc", "def", "ghi", "jk\tlm", "nop", "qrst", "uvw", "xyz", "ß"])
  end

  test "level" do
    assert TreePath.level(~p"") == 0
    assert TreePath.level(~p"a") == 1
    assert TreePath.level(~p"a.b") == 2
    assert TreePath.level(~p"a.b.c") == 3
  end

  test "root", context do
    assert TreePath.root(context[:path]) == TreePath.new("a")
    assert TreePath.root(~p"") == TreePath.new([])
  end

  test "rootname", context do
    assert TreePath.rootname(context[:path]) == "a"
    assert TreePath.rootname(~p"") == ""
  end

  test "parent", context do
    assert TreePath.parent(context[:path]) == TreePath.new(["a", "b"])
    assert TreePath.parent(~p"") == TreePath.new([])
  end

  test "base", context do
    assert TreePath.base(context[:path]) == TreePath.new("c")
    assert TreePath.base(~p"") == TreePath.new([])
  end

  test "basename", context do
    assert TreePath.basename(context[:path]) == "c"
    assert TreePath.basename(~p"") == ""
  end

  test "sibling", context do
    assert TreePath.sibling(context[:path], "d") == TreePath.new(["a", "b", "d"])
    assert TreePath.sibling(~p"", "d") == TreePath.new("d")
  end

  test "append", context do
    p = context[:path]

    assert TreePath.append(p, "d") == TreePath.new(["a", "b", "c", "d"])
    assert TreePath.append(p, ~p"d.e") == TreePath.new(["a", "b", "c", "d", "e"])
    assert TreePath.append(~p"", "d") == TreePath.new("d")
  end

  test "starts_with?", context do
    p = context[:path]

    assert TreePath.starts_with?(p, TreePath.parent(p))
    assert TreePath.starts_with?(p, TreePath.new("a"))
    refute TreePath.starts_with?(p, TreePath.new("b"))
    refute TreePath.starts_with?(p, TreePath.new("c"))
    refute TreePath.starts_with?(p, TreePath.append(p, "x"))
  end

  test "ends_with?", context do
    p = context[:path]

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
