TreeSupervisor.start_link()

DynamicSupervisor.start_child(TreeSourceSupervisor, {SubtreeSource, fn -> [] end})
DynamicSupervisor.start_child(TreeSourceSupervisor, {SubtreeSource, fn -> [] end})
DynamicSupervisor.start_child(TreeSourceSupervisor, {SubtreeSource, fn -> [] end})

Supervisor.count_children(TreeSupervisor) |> IO.inspect(label: "TreeSupervisor")
DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "TreeSourceSupervisor")
