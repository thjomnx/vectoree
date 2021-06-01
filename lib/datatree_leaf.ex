defmodule DataTree.Leaf do
  alias DataTree.{TimeInfo, Status}

  defstruct [:name, :type, :value, :unit, time: TimeInfo.new, status: Status.new]

  def new(name, type, value\\ nil, unit \\ nil) do
    %DataTree.Leaf{name: name, type: type, value: value, unit: unit}
  end
end
