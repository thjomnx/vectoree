defmodule SubtreeSource do
  use GenServer
  import Vectoree.TreePath
  require Logger
  alias Vectoree.{Node, Tree, TreePath}

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
        {~p"sub.node_#{i}", Node.new(:int32, System.system_time(), :nanosecond)}
      end

    state = Tree.normalize(tree)
    {:ok, state}
  end

  @impl true
  def handle_call({:query, path}, _from, state) do
    transformer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

    {:reply, Map.new(state, transformer), state}
  end
end
