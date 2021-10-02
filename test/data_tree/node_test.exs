defmodule DataTree.NodeTest do
  use ExUnit.Case

  import DataTree.{Node, TreePath}

  alias DataTree.{Node, TreePath}

  @moduletag :capture_log

  doctest Node

  test "module exists" do
    assert is_list(Node.module_info())
  end

  test "new via abspath" do
    n = Node.new(~p"")
    assert n.parent == TreePath.new([])
    assert n.name == ""

    n = Node.new(~p"a.b.c")
    assert n.parent == ~p"a.b"
    assert n.name == "c"
  end

  test "new via parent and name" do
    n = Node.new(~p"", "")
    assert n.parent == TreePath.new([])
    assert n.name == ""

    n = Node.new(~p"a.b", "c")
    assert n.parent == ~p"a.b"
    assert n.name == "c"
  end

  test "sigil n" do
    n = ~n""
    assert n.parent == TreePath.new([])
    assert n.name == ""

    n = ~n"a.b.c"
    assert n.parent == ~p"a.b"
    assert n.name == "c"

    # Test whitespace preservation
    n = ~n"  a . b  .  c "
    assert n.parent == ~p"  a . b  "
    assert n.name == "  c "

    # Test whitespace and dot preservation with variable interpolation
    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    n = ~n"m.#{x}. #{y}  .#{z}.n"
    assert n.parent == ~p"m.#{x}. #{y}  .#{z}"
    assert n.name == "n"

    # Test with atom interpolation (single item)
    n = ~n"#{:x}"
    assert n.parent == TreePath.new([])
    assert n.name == "x"

    # Test with atom interpolation (mixed)
    n = ~n"abc.def.ghi.j#{:k}lm.nop.q#{:r}#{:s}t.uvw.xyz"
    assert n.parent == ~p"abc.def.ghi.jklm.nop.qrst.uvw"
    assert n.name == "xyz"

    # Test with variable interpolation
    zero = 0
    kl = "kl"
    r = "r"
    s = "s"
    sz = "ß"
    n = ~n"#{zero}.abc.def.ghi.j#{kl}m.nop.q#{r}#{s}t.uvw.xyz.#{sz}"

    assert n.parent == ~p"0.abc.def.ghi.jklm.nop.qrst.uvw.xyz"
    assert n.name == "ß"
  end
end
