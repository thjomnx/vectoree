defmodule SegmentTableTest do
  use ExUnit.Case

  alias DataTree.TreePath

  doctest SegmentTable

  test "module exists" do
    assert is_list(SegmentTable.module_info())
  end

  test "start_link" do
    {:ok, pid} = SegmentTable.start_link([])
    assert pid != nil
  end

  test "map" do
    {:ok, pid} = SegmentTable.start_link([])

    p0 = SegmentTable.map(pid, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p0 == [1, 2, 3, 4, 5]

    p1 = SegmentTable.map(pid, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p1 == [1, 2, 3, 4, 5]

    p2 = SegmentTable.map(pid, TreePath.new(["x", "y", "z"]))
    assert p2 == [6, 7, 8]

    p3 = SegmentTable.map(pid, TreePath.new(["b", "x", "r", "e", "k"]))
    assert p3 == [9, 1, 10, 8, 4]
  end

  test "map_to_tuple" do
    {:ok, pid} = SegmentTable.start_link([])

    t = SegmentTable.map_to_tuple(pid, TreePath.new(["a", "b", "c", "d", "e"]))
    assert t == {1, 2, 3, 4, 5}
  end
end
