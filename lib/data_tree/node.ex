defmodule DataTree.Node do
  alias DataTree.TreePath

  defstruct [
    :parent,
    :name,
    :type,
    :value,
    :unit,
    modified: 0,
    status: 0,
    children: MapSet.new()
  ]

  def new(%TreePath{} = abs_path) do
    parent = TreePath.parent(abs_path)
    name = TreePath.basename(abs_path)
    new(parent, name)
  end

  def new(
        %TreePath{} = parent,
        name,
        type \\ nil,
        value \\ nil,
        unit \\ nil,
        modified \\ 0,
        status \\ 0,
        children \\ MapSet.new()
      )
      when is_binary(name) do
    %__MODULE__{
      parent: parent,
      name: name,
      type: type,
      value: value,
      unit: unit,
      modified: modified,
      status: status,
      children: children
    }
  end

  defmacro sigil_n({:<<>>, _, [term]}, []) when is_binary(term) do
    [name | parent] =
      term
      |> String.split(TreePath.separator())
      |> Enum.map(&String.trim/1)
      |> Enum.reverse()

    quote do
      DataTree.Node.new(
        DataTree.TreePath.wrap(unquote(parent)),
        unquote(name)
      )
    end
  end

  defmacro sigil_n({:<<>>, _line, terms}, []) do
    escape = fn
      {:"::", _, [expr, _]} ->
        expr

      binary when is_binary(binary) ->
        binary
        |> Macro.unescape_string()
        |> String.trim(TreePath.separator())
    end

    [name | parent] =
      terms
      |> Enum.filter(&(&1 != TreePath.separator()))
      |> Enum.map(&escape.(&1))
      |> Enum.reverse()

    quote do
      DataTree.Node.new(
        DataTree.TreePath.wrap(unquote(parent)),
        unquote(name)
      )
    end
  end

  def path(%__MODULE__{parent: path, name: name}) do
    TreePath.append(path, name)
  end

  def root?(%__MODULE__{parent: path}), do: TreePath.level(path) <= 1
  def leaf?(%__MODULE__{children: children}), do: MapSet.size(children) == 0

  def add_child(%__MODULE__{} = node, name) when is_binary(name) do
    new_children = MapSet.put(node.children, name)
    %{node | children: new_children}
  end

  def children_paths(%__MODULE__{parent: path, name: name, children: children}) do
    for child <- children do
      TreePath.append(path, TreePath.wrap([child, name]))
    end
  end
end
