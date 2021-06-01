defmodule DataTree.Parameter do
  alias DataTree.{TimeInfo, Status}

  defstruct [:name, leaves: [], time: TimeInfo.new, status: Status.new]

  def new(name, type, value\\ nil, unit \\ nil) do
    %DataTree.Parameter{name: name, type: type, value: value, unit: unit}
  end
end
