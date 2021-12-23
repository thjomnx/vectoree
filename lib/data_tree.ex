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

  def update_value(tree, %TreePath{} = path, value) do
    GenServer.cast(tree, {:update_value, path, value})
  end

  @impl true
  def init(table_name) do
    NodeTable.new(table_name)
  end

  @impl true
  def handle_call({:subtree, %TreePath{} = path}, _from, tree) do
    {:reply, NodeTable.subtree(tree, path), tree}
  end

  @impl true
  def handle_call({:insert, %Node{} = node}, _from, tree) do
    {:ok, inserted_node} = NodeTable.insert(tree, node)
    {:reply, inserted_node, tree}
  end

  @impl true
  def handle_cast({:update_value, %TreePath{} = path, value}, tree) do
    NodeTable.update_value(tree, path, value)
    {:noreply, tree}
  end
end
