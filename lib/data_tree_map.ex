defmodule DataTreeMap do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  def new() do
    table = Map.new()
    {:ok, table}
  end

  def insert(table, %Node{} = node) do
    Map.put(table, Node.path(node), node)
    update_parent_of(table, node)
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      Map.put(table, Node.path(node), node)
      update_parent_of(table, node)

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    {:ok, nil}
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    case Map.fetch(table, parent_path) do
      {:ok, parent_node} ->
        Map.put(table, parent_path, Node.add_child(parent_node, name))

      :error ->
        missing_parent = Node.new(parent_path)
        Map.put(table, parent_path, missing_parent)
        update_parent_of(table, missing_parent)
    end
  end

  def lookup(table, %TreePath{} = path) do
    Map.fetch(table, path)
  end

  def subtree(table, %TreePath{} = path) do
    subtree = subtree(table, path, [])
    {:ok, subtree}
  end

  defp subtree(table, %TreePath{} = path, acc) do
    acc =
      case Map.fetch(table, path) do
        {:ok, node} -> [node | acc]
        :error -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
  end
end
