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
    assert ~n"" == Node.new(~p"")
    assert ~n"a.b.c" == Node.new(~p"a.b.c")
  end
end
