defmodule TreeSupervisor do
  use Supervisor
  require Logger

  def start_link(_opts \\ []) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("Starting TreeSupervisor")

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
