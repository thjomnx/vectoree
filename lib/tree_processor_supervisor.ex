defmodule TreeProcessorSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    Logger.info("Starting TreeProcessorSupervisor")

    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def mount_tuple(proc, path) when is_atom(proc) do
    Process.whereis(proc) |> mount_tuple(path)
  end

  def mount_tuple(proc, path) when is_pid(proc) do
    {:mount, proc, path}
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
