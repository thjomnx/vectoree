defmodule DataTree.Parameter do
  alias DataTree.{TimeInfo, Status}

  defstruct [:name, :type, :value, :unit, time: TimeInfo.new, status: Status.new]

  def new(name, type \\ nil, value \\ nil, unit \\ nil) do
    %__MODULE__{name: name, type: type, value: value, unit: unit}
  end
end
