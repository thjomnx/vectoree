import Vectoree.TreePath

alias Vectoree.TreeServer
alias Vectoree.{TreeSource, TreeProcessor, TreeSink}

defmodule Assert do
  def started(result) do
    case result do
      {:ok, pid} -> {:ok, pid}
      _ -> raise("Not started")
    end
  end
end

defmodule CustomTimedSource do
  use Vectoree.TimedTreeSource
  import Vectoree.TreePath
  alias Vectoree.Node

  @impl Vectoree.TimedTreeSource
  def create_tree() do
    for i <- 1..2, into: %{} do
      {~p"node_#{i}", Node.new(:int32, System.system_time(), :nanosecond)}
    end
  end

  @impl Vectoree.TimedTreeSource
  def update_tree({_mount_path, tree}) do
    tree
    |> Stream.filter(fn {_, node} -> node.value != :empty end)
    |> Map.new(fn {path, node} -> {path, %Node{node | value: System.system_time()}} end)
  end
end

{:ok, server_pid} = TreeServer.start_link()

TreeServer.start_child_source(server_pid, CustomTimedSource, ~p"data.local.src1")
|> Assert.started()

TreeServer.start_child_source(server_pid, CustomTimedSource, ~p"data.local.src2")
|> Assert.started()

TreeServer.start_child_source(server_pid, CustomTimedSource, ~p"data.local.src3")
|> Assert.started()

TreeServer.start_child_source(server_pid, CustomTimedSource, ~p"data.local.src4")
|> Assert.started()

TreeServer.start_child_processor(
  server_pid,
  TreeProcessor,
  ~p"data.local.proc1",
  ~p"data.local.src1"
)
|> Assert.started()

TreeServer.start_child_processor(
  server_pid,
  TreeProcessor,
  ~p"data.local.proc2",
  ~p"data.local.src2"
)
|> Assert.started()

TreeServer.start_child_processor(
  server_pid,
  TreeProcessor,
  ~p"data.local.proc4",
  ~p"data.local.src4"
)
|> Assert.started()

TreeServer.start_child_sink(server_pid, TreeSink, ~p"data") |> Assert.started()
TreeServer.start_child_sink(server_pid, TreeSink, ~p"data") |> Assert.started()
TreeServer.start_child_sink(server_pid, TreeSink, ~p"data.local.src1") |> Assert.started()
TreeServer.start_child_sink(server_pid, TreeSink, ~p"data.local.src3") |> Assert.started()

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

Registry.select(TreeSourceRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
|> Enum.map(fn {type, pid, mount_path} ->
  {pid, type, to_string(mount_path)}
end)
|> IO.inspect(label: "TreeSourceRegistry")

Registry.select(TreeSinkRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
|> Enum.map(fn {type, pid, listen_path} ->
  {pid, type, to_string(listen_path)}
end)
|> IO.inspect(label: "TreeSinkRegistry")

# ---

TreeServer.query(server_pid, ~p"data")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data'")

TreeServer.query(server_pid, ~p"data.local.src3.src3a")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data.local.src3.src3a'")

Process.sleep(:infinity)
