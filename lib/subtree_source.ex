defmodule SubtreeSource do
  use GenServer
  import DataTree.TreePath
  require Logger
  alias DataTree.Node

  def start_link(init_arg) do
    Logger.info("Starting SubtreeSource")

    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    {:mount, parent_pid, mount_path} =
      cond do
        is_function(init_arg) -> init_arg.()
        true -> init_arg
      end

    Registry.register(TreeSourceRegistry, parent_pid, mount_path)

    tree =
      for i <- 1..3, j <- 1..5, into: %{} do
        {~p"sub.#{i}.node_#{j}", Node.new(:int32, System.system_time(), :nanoseconds)}
      end

    state = DataTree.normalize(tree)
    {:ok, state}
  end
end
