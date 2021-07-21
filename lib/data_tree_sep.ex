defmodule DataTreeSep do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  def new(opts) do
    table = Keyword.fetch!(opts, :name)
    table_ref = :ets.new(table, [:named_table])
    :ets.new(:pstruct, [:bag, :named_table])
    {:ok, table_ref}
  end

  def insert(table, %Node{} = node) do
    :ets.insert(table, {Node.path(node), node})
    :ets.insert(:pstruct, {node.parent_path, node.name})
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      :ets.insert(table, {Node.path(node), node})
      update_parent_of(:pstruct, node)

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    :ok
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    :ets.insert(table, {parent_path, name})
    update_parent_of(table, TreePath.parent(parent_path), TreePath.basename(parent_path))
  end

  defp update_parent_of(table, parent_path, name) when is_binary(name) do
    unless TreePath.level(parent_path) == 0 do
      :ets.insert(table, {parent_path, name})
      update_parent_of(table, TreePath.parent(parent_path), TreePath.basename(parent_path))
    end
  end

  def lookup(table, %TreePath{} = path) do
    case :ets.lookup(table, path) do
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
      case :ets.lookup(table, path) do
        [{^path, node}] -> [node | acc]
        [] -> [Node.new(path) | acc]
      end

    children =
      case :ets.lookup(:pstruct, path) do
        bag -> Enum.map(bag, fn x -> TreePath.append(path, elem(x, 1)) end)
      end

    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
