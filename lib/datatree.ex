defmodule DataTree do
  use GenServer

  def start_link(opts) do
    table_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table_name, opts)
  end

  def put(table_name, path, node) do
    GenServer.call(table_name, {:create, path, node})
  end

  def lookup(table_name, path) do
    case :ets.lookup(table_name, path) do
      [{^path, node}] -> {:ok, node}
      [] -> :error
    end
  end

  @impl true
  def init(table_name) do
    table = :ets.new(table_name, [:named_table_name, read_concurrency: true])
    {:ok, table}
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
