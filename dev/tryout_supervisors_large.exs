import Vectoree.TreePath

alias Vectoree.TreeServer
alias Vectoree.{TreeSource, TreeProcessor, TreeSink}

defmodule Assert do
  def started(result) do
    case result do
      {:ok, pid} -> {:ok, pid}
      {:error, msg} -> raise("Not started (#{msg})")
      _ -> raise("Not started")
    end
  end
end

defmodule Payload do
  defstruct [
    :type,
    :value,
    :unit,
    status: 0,
    modified: 0
  ]

  def new(
        type \\ :none,
        value \\ :empty,
        unit \\ :none,
        status \\ 0,
        modified \\ 0
      ) do
    %Payload{
      type: type,
      value: value,
      unit: unit,
      status: status,
      modified: modified
    }
  end

  def format(%Payload{type: t, value: v, unit: u, status: s, modified: m}) do
    "#{v} [#{u}] (#{t}/#{s}/#{m})"
  end

  def format(nil) do
    "nil"
  end
end

defmodule CustomTimedSource do
  use Vectoree.TreeSource
  import Vectoree.TreePath

  @impl GenServer
  def init(init_arg) do
    %{mount: mount_path} = TreeServer.args2info(init_arg)
    TreeServer.mount_source(mount_path)

    tree =
      for i <- 1..1500, into: %{} do
        {~p"node_#{i}", Payload.new(:int32, System.system_time(), :nanosecond)}
      end

    tree = Tree.normalize(tree)

    Process.send_after(self(), :update, Enum.random(10000..20000))

    {:ok, %{mount_path: mount_path, local_tree: tree}}
  end

  @impl GenServer
  def handle_info(:update, %{mount_path: mount_path, local_tree: tree} = state) do
    new_tree = update_tree(tree) |> Tree.normalize()
    TreeServer.notify(mount_path, new_tree)

    Process.send_after(self(), :update, Enum.random(10000..30000))

    {:noreply, %{state | mount_path: mount_path, local_tree: new_tree}}
  end

  defp update_tree(tree) do
    tree
    |> Stream.filter(fn {_, payload} -> payload.value != :empty end)
    |> Map.new(fn {path, payload} -> {path, %Payload{payload | value: System.system_time()}} end)
  end
end

defmodule CustomProcessor do
  use Vectoree.TreeProcessor

  @impl GenServer
  def init(init_arg) do
    %{mount: mount_path, listen: listen_path} = TreeServer.args2info(init_arg)
    TreeServer.mount_source(mount_path)
    TreeServer.register_sink(listen_path)

    tree =
      for i <- 1..10, into: %{} do
        {~p"node_#{i}", Payload.new(:int16, 12345, :none)}
      end

    tree = Tree.normalize(tree)

    {:ok, %{mount_path: mount_path, local_tree: tree}}
  end

  @impl Vectoree.TreeProcessor
  def handle_notify(_local_mount_path, local_tree, source_mount_path, source_tree) do
    source_tree
    |> Enum.map(fn {k, v} ->
      "#{TreePath.append(source_mount_path, k)} => #{Payload.format(v)}"
    end)
    |> Enum.each(&IO.inspect(&1, label: " -proc->"))

    local_tree
  end
end

defmodule CustomSink do
  use Vectoree.TreeSink

  @impl GenServer
  def init(init_arg) do
    %{listen: listen_path} = TreeServer.args2info(init_arg)
    TreeServer.register_sink(listen_path)

    {:ok, 0}
  end

  @impl Vectoree.TreeSink
  def handle_notify(source_mount_path, source_tree, state) do
    source_tree
    |> Enum.map(fn {k, v} ->
      "#{TreePath.append(source_mount_path, k)} => #{Payload.format(v)}"
    end)
    |> Enum.each(&IO.inspect(&1, label: " -sink->"))

    state + 1
  end
end

{:ok, server_pid} = TreeServer.start_link()

Enum.each(1..2000, fn i ->
  TreeServer.start_source(server_pid, CustomTimedSource, ~p"data.local.src#{i}")
  |> Assert.started()
end)

Enum.each(1..2000//4, fn i ->
  TreeServer.start_processor(
    server_pid,
    CustomProcessor,
    ~p"data.local.proc#{i}",
    ~p"data.local.src#{i}"
  )
  |> Assert.started()
end)

Enum.each(1..1000, fn i ->
  TreeServer.start_sink(server_pid, CustomSink, ~p"data.local.src#{i}") |> Assert.started()
end)

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

# ---

TreeServer.query(server_pid, ~p"data", chunk_size: 1000)
|> Map.new(fn {k, v} -> {to_string(k), Payload.format(v)} end)
|> IO.inspect(label: "query on 'data'")

Process.sleep(:infinity)
