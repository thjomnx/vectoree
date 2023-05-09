defmodule Vectoree.NodeTest do
  use ExUnit.Case

  alias Vectoree.Node

  @moduletag :capture_log

  doctest Node

  test "module exists" do
    assert is_list(Node.module_info())
  end

  test "to_string" do
    node = Node.new(:int64, -12345, :seconds, 128, 1_234_567_890)
    assert to_string(node) == "-12345 [seconds] (int64/128/1234567890)"
  end
end
