defmodule DataTree.PathTest do
  use ExUnit.Case

  alias DataTree.Path

  @moduletag :capture_log

  doctest Path

  test "module exists" do
    assert is_list(Path.module_info())
  end

  test "new via binary" do
    assert is_struct(Path.new("data"), Path)
  end

  test "new via tuple" do
    assert is_struct(Path.new({"data", "local", "objects"}), Path)
  end

  test "new via list" do
    assert is_struct(Path.new(["data", "local", "objects"]), Path)
  end
end
