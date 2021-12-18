defmodule SegmentTable do
  defstruct [
    :counter,
    forward: Map.new(),
    backward: Map.new()
  ]

  def new(counter_start \\ 1) when is_number(counter_start) do
    %__MODULE__{counter: counter_start}
  end

  def map(%__MODULE__{} = table, segments) when is_list(segments) do
    mapper = fn segment, acc ->
      case Map.fetch(acc.forward, segment) do
        {:ok, value} ->
          {value, acc}

        :error ->
          new_fwd = Map.put(acc.forward, segment, acc.counter)
          new_bwd = Map.put(acc.backward, acc.counter, segment)
          {acc.counter, %{acc | counter: acc.counter + 1, forward: new_fwd, backward: new_bwd}}
      end
    end

    {reduced, new_table} = Enum.map_reduce(segments, table, mapper)
    {List.to_tuple(reduced), new_table}
  end

  def map(%__MODULE__{} = table, segments) when is_tuple(segments) do
    upper_bound = tuple_size(segments) - 1

    expanded =
      for i <- 0..upper_bound do
        Map.get(table.backward, elem(segments, i))
      end

    {expanded, table}
  end
end
