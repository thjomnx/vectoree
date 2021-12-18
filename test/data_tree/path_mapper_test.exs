defmodule DataTree.PathMapperTest do
  use ExUnit.Case

  alias DataTree.{PathMapper, TreePath}

  doctest PathMapper

  test "module exists" do
    assert is_list(PathMapper.module_info())
  end

  test "start_link" do
    {:ok, pid} = PathMapper.start_link([])
    assert pid != nil
  end

  test "map_to_and_from_tuple" do
    {:ok, pid} = PathMapper.start_link([])

    # Test mapping to tuples
    p0 = PathMapper.map_to_tuple(pid, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p0 == {1, 2, 3, 4, 5}

    p1 = PathMapper.map_to_tuple(pid, TreePath.new(["a", "b", "c", "d", "e"]))
    assert p1 == {1, 2, 3, 4, 5}

    p2 = PathMapper.map_to_tuple(pid, TreePath.new(["x", "y", "z"]))
    assert p2 == {6, 7, 8}

    p3 = PathMapper.map_to_tuple(pid, TreePath.new(["b", "x", "r", "e", "k"]))
    assert p3 == {9, 1, 10, 8, 4}

    # Test mapping from tuples
    s0 = PathMapper.map_from_tuple(pid, p0)
    assert s0 == TreePath.new(["a", "b", "c", "d", "e"])

    s1 = PathMapper.map_from_tuple(pid, p1)
    assert s1 == TreePath.new(["a", "b", "c", "d", "e"])

    s2 = PathMapper.map_from_tuple(pid, p2)
    assert s2 == TreePath.new(["x", "y", "z"])

    s3 = PathMapper.map_from_tuple(pid, p3)
    assert s3 == TreePath.new(["b", "x", "r", "e", "k"])
  end
end
