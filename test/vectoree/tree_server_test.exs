defmodule Vectoree.TreeServerTest do
  use ExUnit.Case

  alias Vectoree.TreeServer
  alias Vectoree.TreePath

  @moduletag :capture_log

  defmodule TestSource do
    use Vectoree.TreeSource

    @impl GenServer
    def init(init_arg) do
      %{mount: mount_path} = TreeServer.args2info(init_arg)
      TreeServer.mount_source(mount_path)

      {:ok, %{mount_path: mount_path, local_tree: %{}}}
    end
  end

  defmodule TestProcessor do
    use Vectoree.TreeProcessor

    @impl GenServer
    def init(init_arg) do
      %{mount: mount_path, listen: listen_path} = TreeServer.args2info(init_arg)
      TreeServer.mount_source(mount_path)
      TreeServer.register_sink(listen_path)

      {:ok, %{mount_path: mount_path, local_tree: %{}}}
    end
  end

  defmodule TestSink do
    use Vectoree.TreeSink

    @impl GenServer
    def init(init_arg) do
      %{listen: listen_path} = TreeServer.args2info(init_arg)
      TreeServer.register_sink(listen_path)

      {:ok, 0}
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

    assert TreeServer.args2info(%{mount: mpath, listen: lpath, foo: :bar}) == %{
             mount: mpath,
             listen: lpath
           }
  end

  test "start source", context do
    server = context[:server]

    {:ok, pid} = TreeServer.start_source(server, TestSource, TreePath.new(["a", "r"]))
    assert is_pid(pid)
  end

  test "start processor", context do
    server = context[:server]
    mpath = TreePath.new(["a", "r"])
    lpath = TreePath.new(["a", "l"])

    {:ok, pid} = TreeServer.start_processor(server, TestProcessor, mpath, lpath)
    assert is_pid(pid)
  end

  test "start sink", context do
    server = context[:server]
    lpath = TreePath.new(["a", "l"])

    {:ok, pid} = TreeServer.start_sink(server, TestSink, lpath)
    assert is_pid(pid)
  end
end
