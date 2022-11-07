defmodule DataTree do
  alias DataTree.{Node, TreePath}

  def normalize(tree) do
    Map.keys(tree) |> Enum.reduce(tree, &normalize(&2, &1))
  end

  def normalize(tree, %TreePath{} = path) do
    tree = Map.put_new_lazy(tree, path, &Node.new/0)
    parent = TreePath.parent(path)

    case TreePath.level(parent) do
      0 -> tree
      _ -> normalize(tree, parent)
    end
  end

  def size(tree) do
    map_size(tree)
  end

  def node(tree, %TreePath{} = path) do
    Map.fetch(tree, path)
  end

  def children(tree, %TreePath{} = path) do
    children_level = TreePath.level(path) + 1

    Map.filter(tree, fn {key, _} ->
      TreePath.starts_with?(key, path) && TreePath.level(key) <= children_level
    end)
  end

  def subtree(tree, %TreePath{} = path) do
    Map.filter(tree, fn {key, _} -> TreePath.starts_with?(key, path) end)
  end

  def update_value(tree, value) when is_map(tree) do
    timestamp = system_time()
    update(tree, fn {k, v} -> {k, %Node{v | value: value, modified: timestamp}} end)
  end

  def update_value(tree, %TreePath{} = path, value) when is_map(tree) do
    update(tree, path, fn v -> %Node{v | value: value, modified: system_time()} end)
  end

  def update_status(tree, status) when is_map(tree) do
    timestamp = system_time()
    update(tree, fn {k, v} -> {k, %Node{v | status: status, modified: timestamp}} end)
  end

  def update_status(tree, %TreePath{} = path, status) when is_map(tree) do
    update(tree, path, fn v -> %Node{v | status: status, modified: system_time()} end)
  end

  def update_time_modified(tree, modified) when is_map(tree) do
    update(tree, fn {k, v} -> {k, %Node{v | modified: modified}} end)
  end

  def update_time_modified(tree, %TreePath{} = path, modified) when is_map(tree) do
    update(tree, path, fn v -> %Node{v | modified: modified} end)
  end

  defp update(tree, fun) do
    Map.new(tree, fun)
  end

  defp update(tree, %TreePath{} = path, fun) do
    Map.update(tree, path, &Node.new/0, fun)
  end

  def delete(tree, %TreePath{} = path) do
    Map.reject(tree, fn {k, _} -> TreePath.starts_with?(k, path) end)
  end

  defp system_time() do
    System.system_time()
  end
end
