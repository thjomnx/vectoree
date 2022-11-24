defmodule SubtreeSink do
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    listen_path = init_arg

    Logger.info("Starting SubtreeSink on path #{listen_path}")

    Registry.register(TreeSinkRegistry, listen_path, nil)

    {:ok, []}
  end
end
