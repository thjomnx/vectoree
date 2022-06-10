defmodule TreeServer do
  use GenServer
  import DataTree.TreePath
  require Logger
  alias DataTree.Node

  def start_link(opts \\ []) do
    Logger.info("Starting TreeServer")

    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_opts) do
    tree = %{
      ~p"data.local" => Node.new()
    }

    state = DataTree.normalize(tree)
    {:ok, state}
  end
end
