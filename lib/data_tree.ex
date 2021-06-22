defmodule DataTree do
  use GenServer

  alias DataTree.Node

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def insert(table, node) do
    GenServer.call(table, {:insert, node})
    {:ok, node}
  end

  def lookup(table, path) do
    case :ets.lookup(table, path) do
      [{^path, node}] -> {:ok, node}
      [] -> :error
    end
  end

  def subtree(table, path) do
    subtree(table, path, [])
  end

  defp subtree(table, path, acc) do
    acc =
      case :ets.lookup(table, path) do
        [{^path, node}] -> [node | acc]
        [] -> acc
      end

    node = hd(acc)

    if Node.has_children(node) do
      Enum.reduce(Node.children_paths(node), acc, &subtree(table, &1, &2))
    else
      acc
    end
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
  def handle_call({:insert, %Node{} = node}, from, table) do
    :ets.insert(table, {Node.abs_path(node), node})
    update_parent_of(table, node)
    {:reply, from, table}
  end

  defp update_parent_of(table, %Node{path: parent_path, name: name}) do
    case :ets.lookup(table, parent_path) do
      [{^parent_path, parent}] ->
        :ets.insert(table, {parent_path, Node.add_child(parent, name)})

      [] ->
        missing_parent = Node.new(parent_path)
        :ets.insert(table, {parent_path, missing_parent})
        update_parent_of(table, missing_parent)
    end
  end
end
