defmodule DataTree.Parameter do
  alias DataTree.{TimeInfo, Status}

  defstruct [:path, :name, :type, :value, :unit, time: TimeInfo.new, status: Status.new]

  def new(path, name, type \\ nil, value \\ nil, unit \\ nil) do
    %__MODULE__{path: path, name: name, type: type, value: value, unit: unit}
  end
end
