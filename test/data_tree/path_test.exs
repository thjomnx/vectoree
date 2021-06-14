defmodule DataTree.PathTest do
  use ExUnit.Case

  alias DataTree.Path

  @moduletag :capture_log

  doctest Path

  test "module exists" do
    assert is_list(Path.module_info())
  end

  test "new via binary" do
    assert is_struct(Path.new("a"), Path)
    assert Path.new("a.b.c") |> to_string == "a_2eb_2ec"
  end

  test "new via tuple" do
    assert is_struct(Path.new({"a", "b", "c"}), Path)
  end

  test "new via list" do
    assert is_struct(Path.new(["a", "b", "c"]), Path)
  end

  test "root" do
    p = Path.new(["a", "b", "c"])

    assert Path.root(p) == Path.new("a")
  end

  test "parent" do
    p = Path.new(["a", "b", "c"])

    assert Path.parent(p) == Path.new(["a", "b"])
  end

  test "base" do
    p = Path.new(["a", "b", "c"])

    assert Path.base(p) == Path.new("c")
  end

  test "basename" do
    p = Path.new(["a", "b", "c"])

    assert Path.basename(p) == "c"
  end

  test "sibling" do
    p = Path.new(["a", "b", "c"])

    assert Path.sibling(p, "d") == Path.new(["a", "b", "d"])
  end

  test "append" do
    p = Path.new(["a", "b", "c"])

    assert Path.append(p, "d") == Path.new(["a", "b", "c", "d"])
    assert Path.append(p, {"d", "e"}) == Path.new(["a", "b", "c", "d", "e"])
    assert Path.append(p, ["d", "e"]) == Path.new(["a", "b", "c", "d", "e"])
  end

  test "starts_with?" do
    p = Path.new(["a", "b", "c"])

    assert Path.starts_with?(p, Path.parent(p))
    assert Path.starts_with?(p, Path.new("a"))
    refute Path.starts_with?(p, Path.new("b"))
    refute Path.starts_with?(p, Path.new("c"))
    refute Path.starts_with?(p, Path.new({"a", "d"}))
    refute Path.starts_with?(p, Path.append(p, "x"))
  end

  test "ends_with?" do
    p = Path.new(["a", "b", "c"])

    refute Path.ends_with?(p, Path.parent(p))
    refute Path.ends_with?(p, Path.new("a"))
    refute Path.ends_with?(p, Path.new("b"))
    assert Path.ends_with?(p, Path.new("c"))
    assert Path.ends_with?(p, Path.new({"b", "c"}))
    refute Path.ends_with?(p, Path.append(p, "x"))
  end
end
