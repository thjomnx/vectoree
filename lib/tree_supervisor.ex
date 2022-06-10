defmodule TreeSupervisor do
  use Supervisor
  require Logger

  def start_link(_opts \\ []) do
    Logger.info("Starting TreeSupervisor")

    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def mount_tuple(proc, path) when is_atom(proc) do
    Process.whereis(proc) |> mount_tuple(path)
  end

  def mount_tuple(proc, path) when is_pid(proc) do
    {:mount, proc, path}
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :duplicate, name: TreeSourceRegistry},
      {Registry, keys: :duplicate, name: TreeSinkRegistry},
      {TreeServer, name: TreeServer},
      {TreeSourceSupervisor, name: TreeSourceSupervisor},
      {TreeProcessorSupervisor, name: TreeProcessorSupervisor},
      {TreeSinkSupervisor, name: TreeSinkSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
