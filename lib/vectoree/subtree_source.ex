defmodule SubtreeSource do
  use GenServer
  import Vectoree.TreePath
  require Logger
  alias Vectoree.TreeServer
  alias Vectoree.{Node, Tree, TreePath}

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  defp mount(registry, %TreePath{} = path) do
    Registry.register(registry, :source, path)
  end

  defp get_mount_path(registry) do
    Registry.values(registry, :source, self()) |> hd()
  end

  @impl true
  def init(init_arg) do
    {:mount, mount_path} =
      cond do
        is_function(init_arg) -> init_arg.()
        true -> init_arg
      end

    Logger.info("Starting SubtreeSource on path #{mount_path}")

    mount(TreeSourceRegistry, mount_path)

    tree =
      for i <- 1..2, into: %{} do
        {~p"node_#{i}", Node.new(:int32, System.system_time(), :nanosecond)}
      end

    Process.send_after(self(), :update, 5000)

    {:ok, {mount_path, Tree.normalize(tree)}}
  end

  @impl true
  def handle_info(:update, {mount_path, tree}) do
    new_tree =
      tree
      |> Enum.filter(fn {_, node} -> node.value != :empty end)
      |> Enum.map(fn {path, node} -> {path, %Node{node | value: System.system_time()}} end)
      |> Enum.into(%{})

    root = ~p"data"

    TreeSinkRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$2", :"$3"}}]}])
    |> Stream.filter(fn {_, lpath} -> TreePath.starts_with?(lpath, root) end)
    |> Enum.each(fn {pid, _} -> TreeServer.notify(pid, mount_path, tree) end)

    Process.send_after(self(), :update, 5000)

    {:noreply, {mount_path, Tree.normalize(new_tree)}}
  end

  @impl true
  def handle_call({:query, path}, _from, {_, tree} = state) do
    transformer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

    {:reply, Map.new(tree, transformer), state}
  end
end
