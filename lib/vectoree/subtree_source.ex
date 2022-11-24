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

  def sim_update(server) do
    GenServer.call(server, {:sim_update})
  end

  @impl true
  def init(init_arg) do
    {:mount, mount_path} =
      cond do
        is_function(init_arg) -> init_arg.()
        true -> init_arg
      end

    Logger.info("Starting SubtreeSource on path #{mount_path}")

    Registry.register(TreeSourceRegistry, mount_path, nil)

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

  @impl true
  def handle_call({:sim_update}, _from, state) do
    new_state =
      state
      |> Enum.filter(fn {_, node} -> node.value != :empty end)
      |> Enum.map(fn {path, node} -> {path, %Node{node | value: System.system_time()}} end)
      |> Enum.into(%{})

    # Registry.dispatch(TreeSourceRegistry, )

    {:reply, :ok, Tree.normalize(new_state)}
  end
end
