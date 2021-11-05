defmodule DataTree do
  import DataTree.TreePath

  alias DataTree.{Node, TreePath}

  @idx_path 0
  @idx_type 1
  @idx_value 2
  @idx_unit 3
  @idx_modified 4
  @idx_status 5
  @idx_children 6

  # @elem_pos_path @idx_path + 1
  # @elem_pos_type @idx_type + 1
  # @elem_pos_value @idx_value + 1
  # @elem_pos_unit @idx_unit + 1
  # @elem_pos_modified @idx_modified + 1
  # @elem_pos_status @idx_status + 1
  @elem_pos_children @idx_children + 1

  def new(opts) do
    table = Keyword.fetch!(opts, :name)
    table_ref = :ets.new(table, [:named_table])
    {:ok, table_ref}
  end

  # Only for development/benchmarking purpose
  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      :ets.insert(table, node_to_tuple(node))
      link_parent_of(table, node)
    end

    :ok
  end

  def size(table) do
    :ets.info(table) |> Keyword.fetch!(:size)
  end

  def node(table, %TreePath{} = path) do
    case :ets.lookup(table, path) do
      [tuple] when is_tuple(tuple) -> {:ok, tuple_to_node(tuple)}
      [] -> {:error, "Node not found at path #{path}"}
    end
  end

  def children(table, %TreePath{} = path) do
    subtree(table, path, 2)
  end

  def subtree(table, %TreePath{} = path, limit \\ 0) do
    case subtree(table, path, [], limit, 1) do
      [] -> {:error, "Node not found at path #{path}"}
      result -> {:ok, result}
    end
  end

  defp subtree(table, %TreePath{} = path, acc, limit, level) do
    acc =
      case :ets.lookup(table, path) do
        [tuple] when is_tuple(tuple) -> [tuple_to_node(tuple) | acc]
        [] -> acc
      end

    cond do
      acc == [] || level == limit ->
        acc

      limit <= 0 || level < limit ->
        children = hd(acc) |> Node.children_paths()
        Enum.reduce(children, acc, &subtree(table, &1, &2, limit, level + 1))
    end
  end

  def insert(table, %Node{} = node) do
    :ets.insert(table, node_to_tuple(node))
    link_parent_of(table, node)
    {:ok, node}
  end

  def insert(table, subtree) when is_list(subtree) do
    tuples = for node <- subtree, do: node_to_tuple(node)
    :ets.insert(table, tuples)
    last = List.last(subtree)
    link_parent_of(table, last)
    {:ok, last}
  end

  defp link_parent_of(table, %Node{parent: parent, name: name}) do
    case :ets.lookup(table, parent) do
      [{_, _, _, _, _, _, children}] ->
        new_children = MapSet.put(children, name)
        :ets.update_element(table, parent, {@elem_pos_children, new_children})

      [] ->
        missing_parent = Node.new(parent) |> Node.add_child(name)
        :ets.insert(table, node_to_tuple(missing_parent))
        link_parent_of(table, missing_parent)
    end
  end

  def delete(table, %TreePath{} = path) do
    unlink_parent_of(table, path)

    case :ets.lookup(table, path) do
      [{_, _, _, _, _, _, children}] ->
        children_paths = for c <- children, do: TreePath.append(path, c)
        :ets.delete(table, path)
        Enum.each(children_paths, &delete(table, &1))

      [] ->
        :ok
    end
  end

  defp unlink_parent_of(table, %TreePath{} = path) do
    parent = TreePath.parent(path)
    name = TreePath.basename(path)

    case :ets.lookup(table, parent) do
      [{_, _, _, _, _, _, children}] ->
        new_children = MapSet.delete(children, name)
        :ets.update_element(table, parent, {@elem_pos_children, new_children})

      [] ->
        false
    end
  end

  defp tuple_to_node(tuple) when is_tuple(tuple) do
    path = elem(tuple, @idx_path)

    Node.new(
      TreePath.parent(path),
      TreePath.basename(path),
      elem(tuple, @idx_type),
      elem(tuple, @idx_value),
      elem(tuple, @idx_unit),
      elem(tuple, @idx_modified),
      elem(tuple, @idx_status),
      elem(tuple, @idx_children)
    )
  end

  defp node_to_tuple(%Node{} = node) do
    {
      Node.path(node),
      node.type,
      node.value,
      node.unit,
      node.modified,
      node.status,
      node.children
    }
  end
end
