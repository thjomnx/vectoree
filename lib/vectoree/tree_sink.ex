defmodule Vectoree.TreeSink do
  use GenServer
  require Logger
  alias Vectoree.TreeServer
  alias Vectoree.TreePath

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl true
  def init(init_arg) do
    listen_path = init_arg

    Logger.info("Starting #{__MODULE__} on '#{listen_path}'")

    TreeServer.register_sink(listen_path)

    {:ok, []}
  end

  @impl true
  def handle_cast({:notify, mount_path, tree}, state) do
    Logger.info("Notification received at #{__MODULE__}")

    tree
    |> Enum.map(fn {k, v} -> "#{TreePath.append(mount_path, k)} => #{v}" end)
    |> Enum.each(&IO.inspect(&1, label: " -sink->"))

    {:noreply, state}
  end
end
