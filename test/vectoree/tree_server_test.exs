defmodule Vectoree.TreeServerTest do
  use ExUnit.Case

  alias Vectoree.TreeSource
  alias Vectoree.TreeServer
  alias Vectoree.{Tree, TreePath}

  @moduletag :capture_log

  doctest Tree

  defmodule TestSource do
    use Vectoree.TreeSource

    @impl GenServer
    def init(init_arg) do
      %{mount: mount_path} = TreeServer.args2info(init_arg)
      TreeServer.mount_source(mount_path)

      {:ok, %{mount_path: mount_path, local_tree: %{}}}
    end
  end

  setup do
    {:ok, pid} = TreeServer.start_link()

    {:ok, server: pid}
  end

  test "module exists" do
    assert is_list(TreeServer.module_info())
  end

  test "argument to info" do
    mpath = TreePath.new(["a", "b", "c", "d"])
    lpath = TreePath.new(["a", "b", "c", "d"])

    assert TreeServer.args2info(%{mount: mpath}) == %{mount: mpath}
    assert TreeServer.args2info(%{listen: lpath}) == %{listen: lpath}
    assert TreeServer.args2info(%{mount: mpath, listen: lpath}) == %{mount: mpath, listen: lpath}
    assert TreeServer.args2info(%{mount: mpath, listen: lpath, foo: :bar}) == %{mount: mpath, listen: lpath}
  end

  test "start_test_source", context do
    server = context[:server]

    {:ok, pid} = TreeServer.start_source(server, TestSource, TreePath.new(["a", "r"]))
    assert is_pid(pid)
  end

  # test "start_plain_source", context do
  #   server = context[:server]

  #   {:ok, pid} = TreeServer.start_source(server, TreeSource, TreePath.new(["a", "r"]))
  #   assert is_pid(pid)
  # end
end
