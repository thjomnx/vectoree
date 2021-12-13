defmodule SegmentTable do
  alias DataTree.TreePath

  defstruct [
    :counter,
    forward: Map.new(),
    backward: Map.new()
  ]

  def new(counter_start \\ 1) when is_number(counter_start) do
    %__MODULE__{counter: counter_start}
  end

  def map(%__MODULE__{} = table, %TreePath{segments: segments}) do
    fun = fn segment, acc ->
      case Map.fetch(acc.forward, segment) do
        {:ok, value} ->
          {value, acc}

        :error ->
          new_fwd = Map.put(acc.forward, segment, acc.counter)
          new_bwd = Map.put(acc.backward, acc.counter, segment)
          {acc.counter, %{acc | counter: acc.counter + 1, forward: new_fwd, backward: new_bwd}}
      end
    end

    Enum.map_reduce(segments, table, fun)
  end

  def map(%__MODULE__{} = table, segments) when is_list(segments) do
    list =
      for s <- segments do
        Map.get(table.backward, s)
      end

    {TreePath.wrap(list), table}
  end
end
