defmodule SegmentTable do
  use GenServer

  alias DataTree.TreePath

  def start_link(opts) do
    GenServer.start_link(__MODULE__, 1, opts)
  end

  def map(pid, %TreePath{segments: segments}) do
    GenServer.call(pid, segments)
  end

  def map_to_tuple(pid, %TreePath{} = path) do
    map(pid, path) |> List.to_tuple()
  end

  @impl true
  def init(counter_start) do
    {:ok, {Map.new(), counter_start}}
  end

  @impl true
  def handle_call(segments, _from, {dict, counter}) do
    fun = fn segment, acc ->
      {dict, counter} = acc

      case Map.fetch(dict, segment) do
        {:ok, value} ->
          {value, acc}

        :error ->
          dict = Map.put(dict, segment, counter)
          {counter, {dict, counter + 1}}
      end
    end

    {path_tuple, acc} = Enum.map_reduce(segments, {dict, counter}, fun)

    {:reply, path_tuple, acc}
  end
end
