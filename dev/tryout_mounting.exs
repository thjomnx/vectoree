import DataTree.{Node, TreePath}

DataTree.start_link(name: :vt0)
DataTree.insert(:vt0, ~n"data.local.status")

{:ok, pid0} = DataTree.start_link(name: :vtm0)
DataTree.insert(:vtm0, ~n"vtm0.ticks")

{:ok, pid1} = DataTree.start_link(name: :vtm1)
DataTree.insert(:vtm1, ~n"vtm1.mode")

DataTree.mount(:vt0, ~p"data.local.m0", pid0)
DataTree.mount(:vt0, ~p"data.local.m1", pid1)

{:ok, sub} = DataTree.subtree(:vt0, ~p"data")
sub |> IO.inspect()
