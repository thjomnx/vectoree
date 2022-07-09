import DataTree.TreePath

TreeSupervisor.start_link()

DynamicSupervisor.start_child(
  TreeSourceSupervisor,
  {SubtreeSource, fn -> TreeServer.mount_tuple(TreeServer, ~p"data.local.src1") end}
)

DynamicSupervisor.start_child(
  TreeSourceSupervisor,
  {SubtreeSource, fn -> TreeServer.mount_tuple(TreeServer, ~p"data.local.src2") end}
)

DynamicSupervisor.start_child(
  TreeSourceSupervisor,
  {SubtreeSource, TreeServer.mount_tuple(TreeServer, ~p"data.local.src3")}
)

DynamicSupervisor.start_child(
  TreeSourceSupervisor,
  {SubtreeSource, TreeServer.mount_tuple(TreeServer, ~p"data.local.src4")}
)

DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})
DynamicSupervisor.start_child(TreeProcessorSupervisor, {Agent, fn -> %{} end})

DynamicSupervisor.start_child(TreeSinkSupervisor, {Agent, fn -> [] end})
DynamicSupervisor.start_child(TreeSinkSupervisor, {Agent, fn -> [] end})

# ---

Supervisor.count_children(TreeSupervisor) |> IO.inspect(label: "tree")
DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

Registry.select(TreeSourceRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3", :"$2"}}]}])
|> Enum.map(fn {parent_pid, mount_path, mount_pid} ->
  {parent_pid, to_string(mount_path), mount_pid}
end)
|> IO.inspect()

TreeServer.query(TreeServer, ~p"data") |> IO.inspect()
