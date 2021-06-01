defmodule DataTree do
  use GenServer

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def put(table, path, node) do
    GenServer.call(table, {:create, path, node})
    {:ok, node}
  end

  def lookup(table, path) do
    case :ets.lookup(table, path) do
      [{^path, node}] -> {:ok, node}
      [] -> :error
    end
  end

  @impl true
  def init(table) do
    table_ref = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, table_ref}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:create, path, node}, from, table) do
    :ets.insert(table, {path, node})
    {:reply, from, table}
  end
end
