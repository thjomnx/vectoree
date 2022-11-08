defmodule Vectoree.Node do
  defstruct [
    :type,
    :value,
    :unit,
    status: 0,
    modified: 0
  ]

  def new(
        type \\ :none,
        value \\ :empty,
        unit \\ :none,
        status \\ 0,
        modified \\ 0
      ) do
    %__MODULE__{
      type: type,
      value: value,
      unit: unit,
      status: status,
      modified: modified
    }
  end

  defimpl String.Chars, for: Vectoree.Node do
    def to_string(%Vectoree.Node{type: t, value: v, unit: u, status: s, modified: m}) do
      "#{v} [#{u}] (#{t}/#{s}/#{m})"
    end
  end
end
