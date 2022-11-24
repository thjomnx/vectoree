import Vectoree.TreePath

alias Vectoree.TreeServer

{:ok, server_pid} = TreeServer.start_link()

{:ok, src1} = TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src1")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src2")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src4")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3.src3a")
TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.local.src3.src3a.other.data")

DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})

TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data.local.src1")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data.local.src3")

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

Registry.select(TreeSourceRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
|> Enum.map(fn {mount_path, pid} ->
  {pid, to_string(mount_path)}
end)
|> IO.inspect(label: "TreeSourceRegistry")

Registry.select(TreeSinkRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
|> Enum.map(fn {listen_path, pid} ->
  {pid, to_string(listen_path)}
end)
|> IO.inspect(label: "TreeSinkRegistry")

# ---

TreeServer.query(server_pid, ~p"data")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data'")

TreeServer.query(server_pid, ~p"data.local.src3.src3a")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data.local.src3.src3a'")

SubtreeSource.query(src1, ~p"data") |> IO.inspect(label: "before update")
:ok = SubtreeSource.sim_update(src1)
SubtreeSource.query(src1, ~p"data") |> IO.inspect(label: "after update")
