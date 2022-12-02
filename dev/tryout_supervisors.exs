import Vectoree.TreePath

alias Vectoree.TreeServer

{:ok, server_pid} = TreeServer.start_link()

TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src1")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src2")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src4")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3.src3a")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3.src3a.other.data")

TreeServer.start_child_processor(
  server_pid,
  SubtreeProcessor,
  ~p"data.local.proc1",
  ~p"data.local.src1"
)

TreeServer.start_child_processor(
  server_pid,
  SubtreeProcessor,
  ~p"data.local.proc2",
  ~p"data.local.src2"
)

TreeServer.start_child_processor(
  server_pid,
  SubtreeProcessor,
  ~p"data.local.proc4",
  ~p"data.local.src4"
)

TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data.local.src1")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data.local.src3")

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

Process.sleep(12500)
