defmodule Vectoree.Tree do
  @moduledoc """
  A module containing functions for interacting with the "tree" data structure,
  the latter being a key-value store (map) with keys being `TreePath` structs
  and a payload value of arbitrary type.
  """

  alias Vectoree.TreePath

  @doc """
  Modifies the given tree and starting from the given path (if present), so that all paths are
  present in the key set, which are required to make the tree structure fully
  populated. In other words, the tree is modified so that each entry in the map
  has a particular 'parent' entry with the particular parent path.

  Normalized trees are required, e.g. when using the `Tree.children` function.
  In general, navigating through a non-normalized tree does result in
  non-deterministic behavior.

  ## Examples

      iex> p = Vectoree.TreePath.new(["data", "lore"])
      iex> Vectoree.Tree.normalize(%{p => :payload})
      %{
        %Vectoree.TreePath{segments: ["data"]} => nil,
        %Vectoree.TreePath{segments: ["lore", "data"]} => :payload
      }
  """
  def normalize(tree) do
    Map.keys(tree) |> Enum.reduce(tree, &normalize(&2, &1))
  end

  def normalize(tree, %TreePath{} = path) do
    new_tree = Map.put_new_lazy(tree, path, fn -> nil end)
    parent = TreePath.parent(path)

    case TreePath.level(parent) do
      0 -> new_tree
      _ -> normalize(new_tree, parent)
    end
  end

  @doc """
  Modifies the given tree and starting from the given path (if present), so that all paths
  are removed, which are not required. In other words, the tree is modified so that no entry
  in the map is a leaf with a `nil` payload.

  ## Examples

      iex> p = Vectoree.TreePath.new(["data", "lore"])
      iex> t = Vectoree.Tree.normalize(%{p => nil})
      iex> Vectoree.Tree.denormalize(t)
      %{}
  """
  def denormalize(tree) do
    Map.reject(tree, fn {_, value} -> value == nil end) |> normalize()
  end

  def denormalize(tree, path) do
    if TreePath.level(path) > 0 do
      case Map.fetch(tree, path) do
        {:ok, nil} -> Map.delete(tree, path) |> denormalize(TreePath.parent(path))
        _ -> tree
      end
    else
      tree
    end
  end

  @doc """
  Returns the size of the given tree, which conforms to the number of key-value
  pairs (entries) in the underlying map.

  ## Examples

      iex> p = Vectoree.TreePath.new(["data", "lore"])
      iex> t = %{p => :payload} |> Vectoree.Tree.normalize()
      iex> Vectoree.Tree.size(t)
      2
  """
  def size(tree) do
    map_size(tree)
  end

  @doc """
  Fetches the payload (value) from the given tree for the given path (key).

  ## Examples

      iex> p = Vectoree.TreePath.new(["data", "lore"])
      iex> t = %{p => :payload} |> Vectoree.Tree.normalize()
      iex> Vectoree.Tree.payload(t, p)
      {:ok, :payload}
  """
  def payload(tree, %TreePath{} = path) do
    Map.fetch(tree, path)
  end

  @doc """
  Returns a map, filtered from the given tree, which contains the children for
  the given path including the children's parent entry.

  ## Examples

      iex> p0 = Vectoree.TreePath.new(["data", "ext", "lore"])
      iex> p1 = Vectoree.TreePath.new(["data", "ext", "b4"])
      iex> t = %{p0 => :payload, p1 => :payload} |> Vectoree.Tree.normalize()
      iex> Vectoree.Tree.children(t, Vectoree.TreePath.new(["data", "ext"]))
      %{
        %Vectoree.TreePath{segments: ["ext", "data"]} => nil,
        %Vectoree.TreePath{segments: ["lore", "ext", "data"]} => :payload,
        %Vectoree.TreePath{segments: ["b4", "ext", "data"]} => :payload
      }
  """
  def children(tree, %TreePath{} = path) do
    children_level = TreePath.level(path) + 1

    Map.filter(tree, fn {key, _} ->
      TreePath.starts_with?(key, path) && TreePath.level(key) <= children_level
    end)
  end

  @doc """
  Returns a map, filtered from the given tree, which contains the subtree for
  the given path including the subtree's root entry.

  ## Examples

      iex> p0 = Vectoree.TreePath.new(["data", "ext", "lore"])
      iex> p1 = Vectoree.TreePath.new(["data", "ext", "b4"])
      iex> p2 = Vectoree.TreePath.new(["data", "self", "spot"])
      iex> t = %{p0 => :payload, p1 => :payload, p2 => :payload} |> Vectoree.Tree.normalize()
      iex> Vectoree.Tree.subtree(t, Vectoree.TreePath.new(["data", "ext"]))
      %{
        %Vectoree.TreePath{segments: ["ext", "data"]} => nil,
        %Vectoree.TreePath{segments: ["lore", "ext", "data"]} => :payload,
        %Vectoree.TreePath{segments: ["b4", "ext", "data"]} => :payload
      }
  """
  def subtree(tree, %TreePath{} = path) do
    Map.filter(tree, fn {key, _} -> TreePath.starts_with?(key, path) end)
  end

  @doc """
  Deletes entries from the given tree, whose path (key) starts with the given
  path. When the empty path is given, then the entire tree is deleted. When any
  non-existing path is given, the tree remains untouched. For any existing key,
  the function either deletes a single entry or a subtree (including the
  subtree's root entry).

  Entries which have been added as a result of normalization are kept.

  ## Examples

      iex> p0 = Vectoree.TreePath.new(["data", "ext", "lore"])
      iex> p1 = Vectoree.TreePath.new(["data", "ext", "b4"])
      iex> p2 = Vectoree.TreePath.new(["data", "self", "spot"])
      iex> t = %{p0 => :payload, p1 => :payload, p2 => :payload} |> Vectoree.Tree.normalize()
      iex> t = Vectoree.Tree.delete(t, Vectoree.TreePath.new(["data", "self", "spot"]))
      %{
        %Vectoree.TreePath{segments: ["data"]} => nil,
        %Vectoree.TreePath{segments: ["ext", "data"]} => nil,
        %Vectoree.TreePath{segments: ["lore", "ext", "data"]} => :payload,
        %Vectoree.TreePath{segments: ["b4", "ext", "data"]} => :payload
      }
      iex> Vectoree.Tree.delete(t, Vectoree.TreePath.new(["data", "ext"]))
      %{}
  """
  def delete(tree, %TreePath{} = path) do
    Map.reject(tree, fn {key, _} -> TreePath.starts_with?(key, path) end) |> denormalize()
  end
end
