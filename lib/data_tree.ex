defmodule DataTree do
  use GenServer

  alias DataTree.{Parameter, Path}

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def put(table, parameter) do
    GenServer.call(table, {:create, parameter})
    {:ok, parameter}
  end

  def lookup(table, path) do
    case :ets.lookup(table, path) do
      [{^path, parameter}] -> {:ok, parameter}
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
  def handle_call({:create, parameter}, from, table) do
    path = Path.append(parameter.path, parameter.name)
    :ets.insert(table, {path, parameter})

    parent_path = parameter.path
    parent = case :ets.lookup(table, parent_path) do
      [{^parent_path, p}] -> p
    end

    parent = Parameter.add_child(parent, parameter.name)
    :ets.insert(table, {parent_path, parent})

    {:reply, from, table}
  end
end
