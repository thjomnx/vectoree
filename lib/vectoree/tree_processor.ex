defmodule Vectoree.TreeProcessor do
  use GenServer
  import Vectoree.TreePath
  require Logger
  alias Vectoree.TreeServer
  alias Vectoree.{Node, Tree, TreePath}

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end

  @impl true
  def init(init_arg) do
    %{:mount => mount_path, :listen => listen_path} =
      cond do
        is_function(init_arg) -> init_arg.()
        true -> init_arg
      end

    Logger.info(
      "Starting #{__MODULE__} mounted on '#{mount_path}', listening on '#{listen_path}'"
    )

    TreeServer.mount_source(mount_path)
    TreeServer.register_sink(listen_path)

    tree =
      for i <- 1..2, into: %{} do
        {~p"node_#{i}", Node.new(:int32, System.system_time(), :nanosecond)}
      end

    {:ok, Tree.normalize(tree)}
  end

  @impl true
  def handle_call({:query, path}, _from, state) do
    transformer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

    {:reply, Map.new(state, transformer), state}
  end

  @impl true
  def handle_cast({:notify, mount_path, tree}, state) do
    Logger.info("Notification received at #{__MODULE__}")

    tree
    |> Enum.map(fn {k, v} -> "#{TreePath.append(mount_path, k)} => #{v}" end)
    |> Enum.each(&IO.inspect(&1, label: " -proc->"))

    {:noreply, state}
  end
end
