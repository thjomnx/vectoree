import Vectoree.TreePath

alias Vectoree.TreeServer

{:ok, server_pid} = TreeServer.start_link()

TreeServer.start_child_source(server_pid, SubtreeSource, ~p"data.src1")
TreeServer.start_child_processor(server_pid, SubtreeProcessor, ~p"data.proc1", ~p"data.src1")
TreeServer.start_child_sink(server_pid, SubtreeSink, ~p"data")

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

# ---

TreeServer.query(server_pid, ~p"data")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data'")

Process.sleep(:infinity)
