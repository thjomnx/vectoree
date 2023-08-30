defmodule Vectoree.TreePathTest do
  use ExUnit.Case, async: true

  import Vectoree.TreePath

  alias Vectoree.TreePath

  @moduletag :capture_log

  doctest TreePath

  setup do
    {:ok, path: new(["a", "b", "c"])}
  end

  test "module exists" do
    assert is_list(TreePath.module_info())
  end

  test "new via binary" do
    assert new("").segments == []
    assert new("a").segments == ["a"]
    assert new("  a.b.c  ").segments == ["  a.b.c  "]
  end

  test "new via list" do
    assert new([]).segments == []
    assert new(["a"]).segments == ["a"]
    assert new(["a", "b", "c"]).segments == ["c", "b", "a"]
  end

  test "sigil p" do
    assert ~p"" == new([])
    assert ~p"a.b\nb.c" == new(["a", "b\nb", "c"])

    # Test whitespace preservation
    assert ~p"  a . b  .  c " == new(["  a ", " b  ", "  c "])

    # Test empty segment filtering (multi dots)
    assert ~p".. a...b  ..c.." == new([" a", "b  ", "c"])

    # Test whitespace and dot preservation with variable interpolation
    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    p = ~p"m.#{x}. #{y}  .#{z}.n"
    assert p == new(["m", "  a.b", "   c    ", "d.e  ", "n"])

    # Test with atom interpolation (single item)
    assert ~p"#{:x}" == new(["x"])

    # Test with atom interpolation (mixed) including empty segment filtering (multi dots)
    p = ~p".ab\tc.def..ghi.j#{:k}l\nm.nop.q#{:r}#{:s}t...uvw.xyz..."
    assert p == new(["ab\tc", "def", "ghi", "jkl\nm", "nop", "qrst", "uvw", "xyz"])

    # Test with variable interpolation including empty segment filtering (multi dots)
    zero = 0
    kl = "k\tl"
    r = "r"
    s = "s"
    sz = "ß"
    p = ~p".#{zero}.abc.def..ghi.j#{kl}m.nop.q#{r}#{s}t...uvw.xyz.#{sz}..."

    assert p ==
             new(["0", "abc", "def", "ghi", "jk\tlm", "nop", "qrst", "uvw", "xyz", "ß"])
  end

  test "level" do
    assert level(~p"") == 0
    assert level(~p"a") == 1
    assert level(~p"a.b") == 2
    assert level(~p"a.b.c") == 3
  end

  test "root", context do
    assert root(context[:path]) == new("a")
    assert root(~p"") == new([])
  end

  test "rootname", context do
    assert rootname(context[:path]) == "a"
    assert rootname(~p"") == ""
  end

  test "parent", context do
    assert parent(context[:path]) == new(["a", "b"])
    assert parent(~p"") == new([])
  end

  test "base", context do
    assert base(context[:path]) == new("c")
    assert base(~p"") == new([])
  end

  test "basename", context do
    assert basename(context[:path]) == "c"
    assert basename(~p"") == ""
  end

  test "sibling", context do
    assert sibling(context[:path], "d") == new(["a", "b", "d"])
    assert sibling(~p"", "d") == new("d")
  end

  test "append", context do
    p = context[:path]

    assert append(p, "d") == new(["a", "b", "c", "d"])
    assert append(p, ~p"d.e") == new(["a", "b", "c", "d", "e"])
    assert append(~p"", "d") == new("d")
  end

  test "starts_with?", context do
    p = context[:path]

    assert starts_with?(p, parent(p))
    assert starts_with?(p, new("a"))
    refute starts_with?(p, new("b"))
    refute starts_with?(p, new("c"))
    refute starts_with?(p, append(p, "x"))
  end

  test "ends_with?", context do
    p = context[:path]

    refute ends_with?(p, parent(p))
    refute ends_with?(p, new("a"))
    refute ends_with?(p, new("b"))
    assert ends_with?(p, new("c"))
    refute ends_with?(p, append(p, "x"))
  end

  test "to_string" do
    assert new("  a.b.c  ") |> to_string() == "  a_2eb_2ec  "
  end
end
