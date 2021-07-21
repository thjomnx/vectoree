defmodule DataTree do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  def new(opts) do
    table = Keyword.fetch!(opts, :name)
    table_ref = :ets.new(table, [:named_table])
    {:ok, table_ref}
  end

  def insert(table, %Node{} = node) do
    :ets.insert(table, Node.to_tuple(node))
    update_parent_of(table, node)
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      :ets.insert(table, Node.to_tuple(node))
      update_parent_of(table, node)

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    {:ok, nil}
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    case :ets.lookup(table, parent_path) do
      [tuple] when is_tuple(tuple) ->
        updated_parent = Node.from_tuple(tuple) |> Node.add_child(name) |> Node.to_tuple()
        :ets.insert(table, updated_parent)

      [] ->
        missing_parent = Node.new(parent_path) |> Node.add_child(name)
        :ets.insert(table, Node.to_tuple(missing_parent))
        update_parent_of(table, missing_parent)
    end
  end

  def lookup(table, %TreePath{} = path) do
    case :ets.lookup(table, path) do
      [tuple] when is_tuple(tuple) -> {:ok, Node.from_tuple(tuple)}
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
        [tuple] when is_tuple(tuple) -> [Node.from_tuple(tuple) | acc]
        [] -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
