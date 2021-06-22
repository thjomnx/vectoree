defmodule DataTree.Node do
  alias DataTree.{Status, TimeInfo, TreePath}

  defstruct [:path, :name, :type, :value, :unit, time: TimeInfo.new, status: Status.new, children: []]

  def new(%TreePath{} = abs_path) do
    parent = TreePath.parent(abs_path)
    base = TreePath.basename(abs_path)
    new(parent, base)
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

  def has_children(%__MODULE__{children: children}) do
    length(children) > 0
  end

  def children_paths(%__MODULE__{path: path, name: name, children: children}) do
    for child <- children do
      TreePath.append(path, [name, child])
    end
  end

  def root?(%__MODULE__{path: path}), do: TreePath.level(path) <= 1
  def leaf?(%__MODULE__{children: children}), do: Enum.empty?(children)

  def add_child(%__MODULE__{} = node, name) when is_binary(name) do
    normalized_name = TreePath.normalize(name)

    unless Enum.member?(node.children, normalized_name) do
      new_children = [normalized_name | node.children]
      %{node | children: new_children}
    else
      node
    end
  end
end
