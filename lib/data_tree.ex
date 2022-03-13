defmodule DataTree do
  use GenServer

  alias DataTree.{NodeTable, Node, TreePath}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def node(tree, %TreePath{} = path) do
    NodeTable.node(tree, path)
  end

  def subtree(tree, %TreePath{} = path) do
    GenServer.call(tree, {:subtree, path})
  end

  def insert(tree, %Node{} = node) do
    {:ok, GenServer.call(tree, {:insert, node})}
  end

  def mount(tree, %TreePath{} = path, mount) when is_pid(mount) do
    {:ok, GenServer.call(tree, {:mount, path, mount})}
  end

  def update_value(tree, %TreePath{} = path, value) do
    GenServer.cast(tree, {:update_value, path, value})
  end

  @impl true
  def init(table_name) do
    {:ok, table_ref} = NodeTable.new(table_name)
    {:ok, {table_ref, Map.new()}}
  end

  @impl true
  def handle_call({:subtree, path}, _from, {table_ref, mounts} = state) do
    mtree =
      mounts
      |> Enum.map(fn {path, pid} ->
        Task.async(fn ->
          {:ok, subtree} = DataTree.subtree(pid, TreePath.new([]))
          subtree |> Enum.map(fn n -> Node.rebase(n, path) end)
        end)
      end)
      |> Enum.map(&Task.await/1)

    {:ok, stree} = NodeTable.subtree(table_ref, path)

    {:reply, {:ok, List.flatten(mtree, stree)}, state}
  end

  @impl true
  def handle_call({:insert, %Node{} = node}, _from, {table_ref, _} = state) do
    {:ok, inserted_node} = NodeTable.insert(table_ref, node)
    {:reply, inserted_node, state}
  end

  @impl true
  def handle_call({:insert, subtree}, _from, {table_ref, _} = state) when is_list(subtree) do
    {:ok, last_inserted_node} = NodeTable.insert(table_ref, subtree)
    {:reply, last_inserted_node, state}
  end

  @impl true
  def handle_call({:mount, path, pid}, _from, {table_ref, mounts}) do
    new_mounts = Map.put(mounts, path, pid)
    {:ok, inserted_node} = NodeTable.insert(table_ref, Node.new(path))
    {:reply, inserted_node, {table_ref, new_mounts}}
  end

  @impl true
  def handle_cast({:update_value, path, value}, {table_ref, _} = state) do
    NodeTable.update_value(table_ref, path, value)
    {:noreply, state}
  end
end
