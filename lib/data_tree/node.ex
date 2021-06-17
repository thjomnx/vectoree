defmodule DataTree.Node do
  alias DataTree.{Status, TimeInfo, TreePath}

  defstruct [:path, :name, :type, :value, :unit, time: TimeInfo.new, status: Status.new, children: []]

  def new(%TreePath{} = full_path) do
    new(TreePath.parent(full_path), TreePath.basename(full_path))
  end

  def new(%TreePath{} = parent_path, name, type \\ nil, value \\ nil, unit \\ nil) when is_binary(name) do
    normalized_name = TreePath.normalize(name)
    %__MODULE__{path: parent_path, name: normalized_name, type: type, value: value, unit: unit}
  end

  def sigil_n(term, []) when is_binary(term) do
    String.split(term, TreePath.separator) |> TreePath.new |> new
  end

  def abs_path(%__MODULE__{path: path, name: name}) do
    TreePath.append(path, name)
  end

  def add_child(%__MODULE__{} = node, name) when is_binary(name) do
    normalized_name = TreePath.normalize(name)

    unless Enum.member?(node.children, normalized_name) do
      new_children = List.insert_at(node.children, 0, normalized_name)
      %{node | children: new_children}
    else
      node
    end
  end
end
