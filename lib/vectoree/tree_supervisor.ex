defmodule Vectoree.TreeSupervisor do
  use Supervisor
  require Logger
  alias Vectoree.TreeServer

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
      {DynamicSupervisor, name: TreeSourceSupervisor},
      {DynamicSupervisor, name: TreeProcessorSupervisor},
      {DynamicSupervisor, name: TreeSinkSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
