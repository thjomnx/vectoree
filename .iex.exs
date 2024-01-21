alias Vectoree.{Node, TreePath, TreeServer}
import Vectoree.TreePath

c0 = ~p"a.b.c0"
c1 = ~p"a.b.c1"
b = TreePath.parent(c0)
a = TreePath.root(b)

t = %{
  c0 => :foo,
  c1 => :bar
}

IO.puts("\nExample data in this session from .iex.exs:")
IO.puts("a :: TreePath: '#{a}'")
IO.puts("b :: TreePath: '#{b}'")
IO.puts("c0 :: TreePath: '#{c0}'")
IO.puts("c1 :: TreePath: '#{c1}'")
IO.inspect(t, label: "t :: Map")
