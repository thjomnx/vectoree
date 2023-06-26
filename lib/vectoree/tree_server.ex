defmodule Vectoree.TreeServer do
  use GenServer
  alias Vectoree.{Tree, TreePath}

  def args2info(%{mount: %TreePath{}, listen: %TreePath{}} = map) do
    Map.take(map, [:mount, :listen])
  end

  def args2info(%{mount: %TreePath{}} = map) do
    Map.take(map, [:mount])
  end

  def args2info(%{listen: %TreePath{}} = map) do
    Map.take(map, [:listen])
  end

  def args2info(args) when is_function(args) do
    args.() |> args2info()
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def start_child_source(server, module, %TreePath{} = mount_path) do
    GenServer.call(server, {:add_source, module, mount_path})
  end

  def start_child_processor(server, module, %TreePath{} = mount_path, %TreePath{} = listen_path) do
    GenServer.call(server, {:add_processor, module, mount_path, listen_path})
  end

  def start_child_sink(server, module, %TreePath{} = listen_path) do
    GenServer.call(server, {:add_sink, module, listen_path})
  end

  def mount_source(%TreePath{} = path) do
    Registry.register(TreeSourceRegistry, :source, path)
  end

  def register_sink(%TreePath{} = path) do
    Registry.register(TreeSinkRegistry, :sink, path)
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  def notify(%TreePath{} = path, tree) do
    TreeSinkRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [{:"/=", :"$2", self()}], [{{:"$2", :"$3"}}]}])
    |> Stream.filter(fn {_, lpath} -> TreePath.starts_with?(path, lpath) end)
    |> Enum.each(fn {pid, _} -> notify(pid, path, tree) end)
  end

  def notify(server, %TreePath{} = path, tree) when is_map(tree) do
    GenServer.cast(server, {:notify, path, tree})
  end

  @impl true
  def init(_opts) do
    children = [
      {Registry, keys: :duplicate, name: TreeSourceRegistry},
      {Registry, keys: :duplicate, name: TreeSinkRegistry},
      {DynamicSupervisor, name: TreeSourceSupervisor},
      {DynamicSupervisor, name: TreeProcessorSupervisor},
      {DynamicSupervisor, name: TreeSinkSupervisor}
    ]

    {:ok, supervisor_pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, %{supervisor: supervisor_pid, tree: Map.new()}}
  end

  @impl true
  def handle_call({:add_source, module, mount_path}, _from, %{tree: tree} = state) do
    unless mount_conflict?(mount_path) do
      result =
        DynamicSupervisor.start_child(
          TreeSourceSupervisor,
          {module, %{mount: mount_path}}
        )

      case result do
        {:ok, _} ->
          {:reply, result, %{state | tree: Tree.normalize(tree, mount_path)}}

        _ ->
          {:reply, result, state}
      end
    else
      {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:add_processor, module, mount_path, listen_path}, _from, %{tree: tree} = state) do
    unless mount_conflict?(mount_path) do
      result =
        DynamicSupervisor.start_child(
          TreeProcessorSupervisor,
          {module, %{mount: mount_path, listen: listen_path}}
        )

      case result do
        {:ok, _} ->
          {:reply, result, %{state | tree: Tree.normalize(tree, mount_path)}}

        _ ->
          {:reply, result, state}
      end
    else
      {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:add_sink, module, listen_path}, _from, state) do
    result =
      DynamicSupervisor.start_child(
        TreeSinkSupervisor,
        {module, %{listen: listen_path}}
      )

    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, path}, _from, %{tree: tree} = state) do
    merged_tree =
      TreeSourceRegistry
      |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$2", :"$3"}}]}])
      |> Stream.filter(fn {_, mpath} -> TreePath.starts_with?(mpath, path) end)
      |> Task.async_stream(fn {mpid, mpath} -> query(mpid, mpath) end)
      |> Enum.reduce(tree, fn {:ok, mtree}, acc -> Map.merge(acc, mtree) end)

    {:reply, merged_tree, state}
  end

  defp mount_conflict?(path) do
    TreeSourceRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$2", :"$3"}}]}])
    |> Enum.any?(fn {_, mpath} -> TreePath.starts_with?(path, mpath) end)
  end
end
