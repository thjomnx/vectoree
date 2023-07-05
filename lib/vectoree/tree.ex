defmodule Vectoree.Tree do
  alias Vectoree.TreePath

  def normalize(tree) do
    Map.keys(tree) |> Enum.reduce(tree, &normalize(&2, &1))
  end

  def normalize(tree, %TreePath{} = path) do
    tree = Map.put_new_lazy(tree, path, fn -> nil end)
    parent = TreePath.parent(path)

    case TreePath.level(parent) do
      0 -> tree
      _ -> normalize(tree, parent)
    end
  end

  def size(tree) do
    map_size(tree)
  end

  def payload(tree, %TreePath{} = path) do
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

  def delete(tree, %TreePath{} = path) do
    Map.reject(tree, fn {k, _} -> TreePath.starts_with?(k, path) end)
  end
end
