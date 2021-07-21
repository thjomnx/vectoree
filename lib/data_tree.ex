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

  def insert(table, %Node{} = node) do
    :ets.insert(table, node_to_tuple(node))
    update_parent_of(table, node)
    {:ok, node}
  end

  def populate(table) do
    for i <- 1..100, j <- 1..100, k <- 1..20 do
      node = ~p"data.#{i}.#{j}" |> Node.new("node_#{k}")
      :ets.insert(table, node_to_tuple(node))
      update_parent_of(table, node)

      # "#{i}/#{j}/#{k}" |> IO.puts()
    end

    {:ok, nil}
  end

  defp update_parent_of(table, %Node{parent_path: parent_path, name: name}) do
    case :ets.lookup(table, parent_path) do
      [{_, _, _, _, _, _, children}] ->
        new_children =
          unless Enum.member?(children, name) do
            [name | children]
          else
            children
          end

        :ets.update_element(table, parent_path, {@elem_pos_children, new_children})

      [] ->
        missing_parent = Node.new(parent_path) |> Node.add_child(name)
        :ets.insert(table, node_to_tuple(missing_parent))
        update_parent_of(table, missing_parent)
    end
  end

  def lookup(table, %TreePath{} = path) do
    case :ets.lookup(table, path) do
      [tuple] when is_tuple(tuple) -> {:ok, tuple_to_node(tuple)}
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
        [tuple] when is_tuple(tuple) -> [tuple_to_node(tuple) | acc]
        [] -> acc
      end

    children = hd(acc) |> Node.children_paths()
    Enum.reduce(children, acc, &subtree(table, &1, &2))
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
