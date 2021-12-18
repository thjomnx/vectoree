defmodule DataTree.PathMapper do
  use GenServer

  alias SegmentTable
  alias DataTree.TreePath

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def map_to_tuple(pid, %TreePath{segments: segments}) do
    GenServer.call(pid, segments)
  end

  def map_from_tuple(pid, segments) when is_tuple(segments) do
    GenServer.call(pid, segments) |> TreePath.wrap()
  end

  @impl true
  def init(_opts) do
    {:ok, SegmentTable.new()}
  end

  @impl true
  def handle_call(segments, _from, table) do
    {mapped_segments, new_table} = SegmentTable.map(table, segments)
    {:reply, mapped_segments, new_table}
  end
end
