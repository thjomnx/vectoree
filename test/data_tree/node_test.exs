defmodule DataTree.NodeTest do
  use ExUnit.Case

  import DataTree.{Node, TreePath}
  alias DataTree.Node

  @moduletag :capture_log

  doctest Node

  test "module exists" do
    assert is_list(Node.module_info())
  end

  test "new via abspath" do
    assert is_struct(Node.new(~p""), Node)
    assert is_struct(Node.new(~p"a.b.c"), Node)
  end

  test "new via parent" do
    assert is_struct(Node.new(~p"", ""), Node)
    assert is_struct(Node.new(~p"a.b", "c"), Node)
  end

  test "sigil n" do
    assert is_struct(~n"", Node)
    assert is_struct(~n"a.b.c", Node)

    x = "  a.b"
    y = "  c  "
    z = "d.e  "
    n = ~n"#{x}.#{y}.#{z}"
    assert is_struct(n, Node)
    # assert to_string(n.parent_path) == "a.b.c.d"
  end
end
