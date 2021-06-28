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
    assert is_struct(Node.new(~t""), Node)
    assert is_struct(Node.new(~t"a.b.c"), Node)
  end

  test "new via parent" do
    assert is_struct(Node.new(~t"", ""), Node)
    assert is_struct(Node.new(~t"a.b", "c"), Node)
  end

end
