defmodule SubtreeSource do
  use GenServer
  import DataTree.TreePath
  require Logger
  alias DataTree.{Node, TreePath}

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  @impl true
  def init(init_arg) do
    {:mount, parent_pid, mount_path} =
      cond do
        is_function(init_arg) -> init_arg.()
        true -> init_arg
      end

    Logger.info("Starting SubtreeSource on path #{mount_path}")

    Registry.register(TreeSourceRegistry, parent_pid, mount_path)

    tree =
      for i <- 1..2, into: %{} do
        {~p"sub.node_#{i}", Node.new(:int32, System.system_time(), :nanoseconds)}
      end

    state = DataTree.normalize(tree)
    {:ok, state}
  end

  @impl true
  def handle_call({:query, path}, _from, state) do
    rebased = Map.new(state, fn {k, v} -> {TreePath.append(path, k), v} end)

    {:reply, rebased, state}
  end
end
