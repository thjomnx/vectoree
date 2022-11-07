defmodule TreeServer do
  use GenServer
  import DataTree.TreePath
  require Logger
  alias DataTree.{Node, TreePath}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  def mount_tuple(name, %TreePath{} = path) when is_atom(name) do
    pid = Process.whereis(name)
    mount_tuple(pid, path)
  end

  def mount_tuple(pid, %TreePath{} = path) when is_pid(pid) do
    {_, _, ppid} = find_parent(pid, path)
    {:mount, ppid, path}
  end

  defp find_parent(pid, path) do
    parent_path = TreePath.parent(path)

    TreeSourceRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3", :"$2"}}]}])
    |> Stream.filter(fn {_, mpath, _} -> TreePath.starts_with?(parent_path, mpath) end)
    |> Enum.max_by(fn {_, mpath, _} -> TreePath.level(mpath) end, fn -> {nil, nil, pid} end)
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting TreeServer")

    tree = %{
      ~p"data.local" => Node.new()
    }

    state = DataTree.normalize(tree)
    {:ok, state}
  end

  @impl true
  def handle_call({:query, path}, _from, state) do
    merged_tree =
      TreeSourceRegistry
      |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3", :"$2"}}]}])
      |> Stream.filter(fn {_, mpath, _} -> TreePath.starts_with?(mpath, path) end)
      |> Task.async_stream(fn {_, mpath, mpid} -> SubtreeSource.query(mpid, mpath) end)
      |> Enum.reduce(state, fn {:ok, mtree}, acc -> Map.merge(acc, mtree) end)

    {:reply, merged_tree, state}
  end
end
