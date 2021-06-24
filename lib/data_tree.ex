defmodule DataTree do
  use GenServer

  alias DataTree.{Node, TreePath}

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def insert(table, %Node{} = node) do
    GenServer.call(table, {:insert, node})
    {:ok, node}
  end

  def lookup(table, %TreePath{} = path) do
    case :ets.lookup(table, path) do
      [{^path, node}] -> {:ok, node}
      [] -> :error
    end
  end

  def subtree(table, %TreePath{} = path) do
    GenServer.call(table, {:subtree, path})
  end

  @impl true
  def init(table) do
    table_ref = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, table_ref}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:insert, %Node{} = node}, _from, table) do
    :ets.insert(table, {Node.path(node), node})
    update_parent_of(table, node)
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:subtree, %TreePath{} = path}, _from, table) do
    subtree = subtree(table, path, [])
    {:reply, subtree, table}
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    case :ets.lookup(table, parent_path) do
      [{^parent_path, parent_node}] ->
        :ets.insert(table, {parent_path, Node.add_child(parent_node, name)})

      [] ->
        missing_parent = Node.new(parent_path)
        :ets.insert(table, {parent_path, missing_parent})
        update_parent_of(table, missing_parent)
    end
  end

  defp subtree(table, %TreePath{} = path, acc) do
    acc =
      case :ets.lookup(table, path) do
        [{^path, node}] -> [node | acc]
        [] -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
