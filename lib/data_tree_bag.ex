defmodule DataTreeBag do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  def new(opts) do
    table = Keyword.fetch!(opts, :name)
    table_ref = :ets.new(table, [:bag, :named_table])
    {:ok, table_ref}
  end

  def insert(table, %Node{} = node) do
    :ets.insert(table, {node.parent_path, node})
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      :ets.insert(table, {node.parent_path, node})

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    {:ok, nil}
  end

  def lookup(table, %TreePath{} = path) do
    parent_path = TreePath.parent(path)
    name = TreePath.basename(path)

    case :ets.lookup(table, parent_path) do
      bag ->
        node = Enum.find(bag, fn x -> elem(x, 1).name == name end)
        {:ok, node}
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
        [] -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
