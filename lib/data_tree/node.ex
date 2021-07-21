defmodule DataTree.Node do
  alias DataTree.TreePath

  @idx_path 0
  @idx_type 1
  @idx_value 2
  @idx_unit 3
  @idx_modified 4
  @idx_status 5
  @idx_children 6

  defstruct [
    :parent_path,
    :name,
    :type,
    :value,
    :unit,
    modified: 0,
    status: 0,
    children: []
  ]

  def new(%TreePath{} = abs_path) do
    parent_path = TreePath.parent(abs_path)
    name = TreePath.basename(abs_path)
    new(parent_path, name)
  end

  def new(
        %TreePath{} = parent_path,
        name,
        type \\ nil,
        value \\ nil,
        unit \\ nil,
        modified \\ 0,
        status \\ 0,
        children \\ []
      )
      when is_binary(name) do
    normalized_name = TreePath.normalize(name)

    %__MODULE__{
      parent_path: parent_path,
      name: normalized_name,
      type: type,
      value: value,
      unit: unit,
      modified: modified,
      status: status,
      children: children
    }
  end

  defmacro sigil_n({:<<>>, _, [term]}, []) when is_binary(term) do
    [name | parent_path] =
      term
      |> String.split(DataTree.TreePath.separator())
      |> Enum.reverse()

    quote do
      DataTree.Node.new(
        DataTree.TreePath.wrap(unquote(parent_path)),
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
        |> :elixir_interpolation.unescape_string()
        |> String.trim(DataTree.TreePath.separator())
    end

    flatsplit = fn
      binary when is_binary(binary) ->
        binary
        |> String.split(".")
        |> Enum.reverse()

      other ->
        other
    end

    [name | parent_path] =
      terms
      |> Enum.filter(&(&1 != DataTree.TreePath.separator()))
      |> Enum.map(&escape.(&1))
      |> Enum.map(&flatsplit.(&1))
      |> Enum.reverse()

    quote do
      DataTree.Node.new(
        DataTree.TreePath.wrap(unquote(parent_path)),
        unquote(name)
      )
    end
  end

  def path(%__MODULE__{parent_path: path, name: name}) do
    TreePath.append(path, name)
  end

  def root?(%__MODULE__{parent_path: path}), do: TreePath.level(path) <= 1
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

  def children_paths(%__MODULE__{parent_path: path, name: name, children: children}) do
    for child <- children do
      TreePath.append(path, [name, child])
    end
  end

  def from_tuple(tuple) when is_tuple(tuple) do
    path = elem(tuple, @idx_path)

    new(
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

  def to_tuple(%__MODULE__{} = node) do
    {
      path(node),
      node.type,
      node.value,
      node.unit,
      node.modified,
      node.status,
      node.children
    }
  end
end
