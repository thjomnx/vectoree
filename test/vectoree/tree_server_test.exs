defmodule Vectoree.TreeServerTest do
  use ExUnit.Case

  import Vectoree.TreePath

  alias Vectoree.TreeServer
  alias Vectoree.{Tree, TreePath}

  @moduletag :capture_log

  doctest TreeServer

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

  defp assert_down(name) do
    ref = Process.monitor(name)
    assert_receive({:DOWN, ^ref, _, _, _})
  end

  setup do
    tree =
      Tree.normalize(%{
        ~p"a.b.c.d" => :foo,
        ~p"a.e.f" => :bar
      })

    {:ok, pid} = start_supervised({TreeServer, tree: tree})

    on_exit(fn ->
      assert_down(TreeSourceRegistry)
      assert_down(TreeSinkRegistry)
    end)

    {:ok, server: pid}
  end

  test "module exists" do
    assert is_list(TreeServer.module_info())
  end

  test "argument to info" do
    mpath = ~p"a.b.c.d"
    lpath = ~p"a.b.c"

    assert TreeServer.args2info(%{mount: mpath}) == %{mount: mpath}
    assert TreeServer.args2info(%{listen: lpath}) == %{listen: lpath}
    assert TreeServer.args2info(%{mount: mpath, listen: lpath}) == %{mount: mpath, listen: lpath}

    assert TreeServer.args2info(%{mount: mpath, listen: lpath, foo: :bar}) == %{
             mount: mpath,
             listen: lpath
           }

    assert TreeServer.args2info(fn -> %{mount: mpath, listen: lpath, foo: :bar} end) == %{
             mount: mpath,
             listen: lpath
           }
  end

  test "start source", context do
    server = context[:server]
    mpath = ~p"a.r"

    {:ok, pid} = TreeServer.start_source(server, TestSource, mpath)
    assert is_pid(pid)
  end

  test "stop source", context do
    server = context[:server]
    mpath = ~p"a.r"

    {:ok, pid} = TreeServer.start_source(server, TestSource, mpath)
    assert TreeServer.stop_source(server, pid) == :ok
  end

  test "start processor", context do
    server = context[:server]
    mpath = ~p"a.r"
    lpath = ~p"a.l"

    {:ok, pid} = TreeServer.start_processor(server, TestProcessor, mpath, lpath)
    assert is_pid(pid)
  end

  test "stop processor", context do
    server = context[:server]
    mpath = ~p"a.r"
    lpath = ~p"a.l"

    {:ok, pid} = TreeServer.start_processor(server, TestProcessor, mpath, lpath)
    assert TreeServer.stop_processor(server, pid) == :ok
  end

  test "start sink", context do
    server = context[:server]
    lpath = ~p"a.l"

    {:ok, pid} = TreeServer.start_sink(server, TestSink, lpath)
    assert is_pid(pid)
  end

  test "stop sink", context do
    server = context[:server]
    lpath = ~p"a.l"

    {:ok, pid} = TreeServer.start_sink(server, TestSink, lpath)
    assert TreeServer.stop_sink(server, pid) == :ok
  end

  test "mount conflict", context do
    server = context[:server]
    path = ~p"a.x"

    {:ok, _pid} = TreeServer.start_source(server, TestSource, path)
    {:error, msg} = TreeServer.start_processor(server, TestProcessor, path, path)

    assert String.contains?(msg, "conflict")
  end

  test "query", context do
    server = context[:server]

    tree = TreeServer.query(server, ~p"a")
    assert map_size(tree) == 6
    assert tree[~p"a"] == nil
    assert tree[~p"a.b"] == nil
    assert tree[~p"a.b.c"] == nil
    assert tree[~p"a.b.c.d"] == :foo
    assert tree[~p"a.e"] == nil
    assert tree[~p"a.e.f"] == :bar

    tree = TreeServer.query(server, ~p"a.e")
    assert map_size(tree) == 2
    assert tree[~p"a.e"] == nil
    assert tree[~p"a.e.f"] == :bar

    tree = TreeServer.query(server, ~p"a.e.f")
    assert map_size(tree) == 1
    assert tree[~p"a.e.f"] == :bar
  end

  test "query apply", context do
    server = context[:server]

    fun = fn _ctrl, chunk, acc -> Map.keys(chunk) ++ acc end
    list = TreeServer.query_apply(server, ~p"a", [], fun)
    assert length(list) == 6
    assert ~p"a" in list
    assert ~p"a.b" in list
    assert ~p"a.b.c" in list
    assert ~p"a.b.c.d" in list
    assert ~p"a.e" in list
    assert ~p"a.e.f" in list

    fun = fn _ctrl, chunk, acc -> Map.values(chunk) ++ acc end
    list = TreeServer.query_apply(server, ~p"a.e", [], fun)
    assert length(list) == 2
    assert nil in list
    assert :bar in list

    list = TreeServer.query_apply(server, ~p"a.e.f", [], fun)
    assert length(list) == 1
    assert nil not in list
    assert :bar in list
  end

  test "query apply with chunks", context do
    server = context[:server]

    fun = fn ctrl, chunk, acc -> [{ctrl, chunk} | acc] end
    list = TreeServer.query_apply(server, ~p"a", [], fun, chunk_size: 2)
    assert length(list) == 4

    count =
      Enum.count(list, fn
        {:ok, _} -> true
        _ -> false
      end)

    assert count == 1

    count =
      Enum.count(list, fn
        {:cont, _} -> true
        _ -> false
      end)

    assert count == 3
  end
end
