defmodule Vectoree.TreeServer do
  use GenServer
  import Vectoree.TreePath
  require Logger
  alias Vectoree.{Node, Tree, TreePath}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def start_child_source(server, module, %TreePath{} = path) do
    GenServer.call(server, {:add_source, module, path})
  end

  def start_child_sink(server, module, %TreePath{} = path) do
    GenServer.call(server, {:add_sink, module, path})
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  def mount_tuple(name, %TreePath{} = path) when is_atom(name) do
    pid = Process.whereis(name)
    mount_tuple(pid, path)
  end

  def mount_tuple(pid, %TreePath{} = path) when is_pid(pid) do
    {:mount, path}
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting TreeServer")

    children = [
      {Registry, keys: :unique, name: TreeSourceRegistry},
      {Registry, keys: :unique, name: TreeSinkRegistry},
      {DynamicSupervisor, name: TreeSourceSupervisor},
      {DynamicSupervisor, name: TreeProcessorSupervisor},
      {DynamicSupervisor, name: TreeSinkSupervisor}
    ]

    {:ok, supervisor_pid} = Supervisor.start_link(children, strategy: :one_for_one)

    tree = %{
      ~p"data.local" => Node.new()
    }

    {:ok, %{supervisor: supervisor_pid, tree: Tree.normalize(tree)}}
  end

  @impl true
  def handle_call({:add_source, module, path}, _from, state) do
    result = DynamicSupervisor.start_child(TreeSourceSupervisor, {module, {:mount, path}})

    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_sink, module, path}, _from, state) do
    result = DynamicSupervisor.start_child(TreeSinkSupervisor, {module, path})

    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, path}, _from, %{tree: tree} = state) do
    merged_tree =
      TreeSourceRegistry
      |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
      |> Stream.filter(fn {mpath, _} -> TreePath.starts_with?(mpath, path) end)
      |> Task.async_stream(fn {mpath, mpid} -> SubtreeSource.query(mpid, mpath) end)
      |> Enum.reduce(tree, fn {:ok, mtree}, acc -> Map.merge(acc, mtree) end)

    {:reply, merged_tree, state}
  end
end
