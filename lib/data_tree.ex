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

    visit_parent(table, parameter)

    {:reply, from, table}
  end

  defp visit_parent(table, %Parameter{path: path, name: name}) do
    case :ets.lookup(table, path) do
      [{^path, parent}] ->
        :ets.insert(table, {path, Parameter.add_child(parent, name)})
      [] ->
        new_parent = Parameter.new(Path.parent(path), Path.basename(path))
        :ets.insert(table, {path, new_parent})
        visit_parent(table, new_parent)
    end
  end
end
