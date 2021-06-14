defmodule DataTree.Parameter do
  alias DataTree.{Path, Status, TimeInfo}

  defstruct [:path, :name, :type, :value, :unit, time: TimeInfo.new, status: Status.new, children: []]

  def new(%Path{} = full_path) do
    new(Path.parent(full_path), Path.basename(full_path))
  end

  def new(%Path{} = parent_path, name, type \\ nil, value \\ nil, unit \\ nil) when is_binary(name) do
    normalized_name = Path.normalize(name)
    %__MODULE__{path: parent_path, name: normalized_name, type: type, value: value, unit: unit}
  end

  def abs_path(%__MODULE__{path: path, name: name}) do
    Path.append(path, name)
  end

  def add_child(%__MODULE__{} = parameter, name) when is_binary(name) do
    normalized_name = Path.normalize(name)

    unless Enum.member?(parameter.children, normalized_name) do
      new_children = List.insert_at(parameter.children, 0, normalized_name)
      %{parameter | children: new_children}
    else
      parameter
    end
  end
end
