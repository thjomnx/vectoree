defmodule SegmentTableTest do
  use ExUnit.Case

  alias DataTree.TreePath

  doctest SegmentTable

  test "module exists" do
    assert is_list(SegmentTable.module_info())
  end

  test "map" do
    table = SegmentTable.new()

    # Test forward mapping
    {p0, table} = SegmentTable.map(table, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p0 == [1, 2, 3, 4, 5]

    {p1, table} = SegmentTable.map(table, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p1 == [1, 2, 3, 4, 5]

    {p2, table} = SegmentTable.map(table, TreePath.new(["x", "y", "z"]))
    assert p2 == [6, 7, 8]

    {p3, table} = SegmentTable.map(table, TreePath.new(["b", "x", "r", "e", "k"]))
    assert p3 == [9, 1, 10, 8, 4]

    # Test backward mapping
    {s0, table} = SegmentTable.map(table, p0)
    assert s0 == TreePath.new(["a", "b", "c", "d", "e"])

    {s1, table} = SegmentTable.map(table, p1)
    assert s1 == TreePath.new(["a", "b", "c", "d", "e"])

    {s2, table} = SegmentTable.map(table, p2)
    assert s2 == TreePath.new(["x", "y", "z"])

    {s3, _table} = SegmentTable.map(table, p3)
    assert s3 == TreePath.new(["b", "x", "r", "e", "k"])
  end
end
