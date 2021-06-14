defmodule DataTree do
  use GenServer

  alias DataTree.Parameter

  def start_link(opts) do
    table = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table, opts)
  end

  def insert(table, parameter) do
    GenServer.call(table, {:insert, parameter})
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
  def handle_call({:insert, %Parameter{} = parameter}, from, table) do
    :ets.insert(table, {Parameter.abs_path(parameter), parameter})
    update_parent_of(table, parameter)
    {:reply, from, table}
  end

  defp update_parent_of(table, %Parameter{path: parent_path, name: name}) do
    case :ets.lookup(table, parent_path) do
      [{^parent_path, parent}] ->
        :ets.insert(table, {parent_path, Parameter.add_child(parent, name)})
      [] ->
        missing_parent = Parameter.new(parent_path)
        :ets.insert(table, {parent_path, missing_parent})
        update_parent_of(table, missing_parent)
    end
  end
end
