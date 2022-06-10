defmodule TreeServer do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    Logger.info("Starting TreeServer")

    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(init_arg) do
    {:ok, init_arg}
  end
end
