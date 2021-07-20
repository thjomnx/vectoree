defmodule DataTreeShards do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  def new(opts) do
    table = Keyword.fetch!(opts, :name)
    table_ref = ExShards.new(table, [:named_table])
    {:ok, table_ref}
  end

  def insert(table, %Node{} = node) do
    ExShards.insert(table, {Node.path(node), node})
    update_parent_of(table, node)
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      ExShards.insert(table, {Node.path(node), node})
      update_parent_of(table, node)

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    {:ok, nil}
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    case ExShards.lookup(table, parent_path) do
      [{^parent_path, parent_node}] ->
        ExShards.insert(table, {parent_path, Node.add_child(parent_node, name)})

      [] ->
        missing_parent = Node.new(parent_path)
        ExShards.insert(table, {parent_path, missing_parent})
        update_parent_of(table, missing_parent)
    end
  end

  def lookup(table, %TreePath{} = path) do
    case ExShards.lookup(table, path) do
      [{^path, node}] -> {:ok, node}
      [] -> :error
    end
  end

  def subtree(table, %TreePath{} = path) do
    subtree = subtree(table, path, [])
    {:ok, subtree}
  end

  defp subtree(table, %TreePath{} = path, acc) do
    acc =
      case ExShards.lookup(table, path) do
        [{^path, node}] -> [node | acc]
        [] -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
