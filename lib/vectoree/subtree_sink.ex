defmodule SubtreeSink do
  use GenServer
  require Logger
  alias Vectoree.TreePath

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    listen_path = init_arg

    Logger.info("Starting SubtreeSink on path #{listen_path}")

    TreeServer.register_sink(listen_path)

    {:ok, []}
  end

  @impl true
  def handle_cast({:notify, mount_path, tree}, state) do
    Logger.info("Notification received at SubtreeSink")

    tree
    |> Enum.map(fn {k, v} -> "#{TreePath.append(mount_path, k)} => #{v}" end)
    |> Enum.each(&IO.inspect(&1, label: "arrived at sink"))

    {:noreply, state}
  end
end
