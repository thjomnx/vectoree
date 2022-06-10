defmodule SubtreeSource do
  use GenServer
  import DataTree.TreePath
  require Logger
  alias DataTree.Node

  def start_link(opts \\ []) do
    Logger.info("Starting SubtreeSource")

    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    tree =
      for i <- 1..3, j <- 1..5, into: %{} do
        {~p"data.#{i}.node_#{j}", Node.new(:int32, System.system_time(), :nanoseconds)}
      end

    state = DataTree.normalize(tree)
    {:ok, state}
  end
end
