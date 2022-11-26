defmodule SubtreeSink do
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def notify(server, data) do
    GenServer.cast(server, {:notify, data})
  end

  @impl true
  def init(init_arg) do
    listen_path = init_arg

    Logger.info("Starting SubtreeSink on path #{listen_path}")

    Registry.register(TreeSinkRegistry, :sink, listen_path)

    {:ok, []}
  end

  @impl true
  def handle_cast({:notify, _data}, state) do
    Logger.info("Notification received")

    {:noreply, state}
  end
end
