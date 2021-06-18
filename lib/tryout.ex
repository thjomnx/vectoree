defmodule Tryout do
  use Application

  import DataTree.{Node, TreePath}

  alias DataTree.{Node, TreePath}

  def start(_type, _args) do
    run_proto()
    {:ok, self()}
  end

  def run_proto do
    DataTree.start_link(name: :ptree)

    {:ok, data} = DataTree.insert(:ptree, ~n"data")
    {:ok, local} = DataTree.insert(:ptree, ~n"data.local")

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    {:ok, ticks} = DataTree.insert(:ptree, Node.new(~t"data.local", "ticks", :int32, timestamp, :milliseconds))

    IO.inspect(data)
    IO.inspect(local)
    IO.inspect(ticks)

    IO.puts(ticks.value)

    Enum.map(
      18..28,
      fn i ->
        name = "param" <> Integer.to_string(i)
        DataTree.insert(:ptree, ~n"data.#{name}")
      end
    )

    DataTree.lookup(:ptree, ~n"data.param23") |> IO.inspect

    # -----------

    p = TreePath.new(["data", "local", "objects"])
    IO.inspect(p)

    TreePath.parent(p) |> IO.puts
    TreePath.append(p, "myClock") |> IO.puts
    TreePath.append(p, ["remote", "peer", "dark_star"]) |> IO.puts
    TreePath.root(p) |> IO.puts
    TreePath.new("data") |> TreePath.parent |> IO.puts
    TreePath.sibling(p, "monitors") |> IO.puts
    TreePath.new(["", "data", "", "", "", "raw", "", "proj.x"]) |> IO.puts

    IO.puts("-------------------------")

    TreePath.starts_with?(p, TreePath.parent(p)) |> IO.puts
    TreePath.starts_with?(p, TreePath.new("data")) |> IO.puts
    TreePath.starts_with?(p, TreePath.new("local")) |> IO.puts
    TreePath.starts_with?(p, TreePath.new("objects")) |> IO.puts
    TreePath.starts_with?(p, TreePath.new(["data", "remote"])) |> IO.puts
    TreePath.starts_with?(p, TreePath.append(p, "blah")) |> IO.puts

    IO.puts("-------------------------")

    TreePath.ends_with?(p, TreePath.parent(p)) |> IO.puts
    TreePath.ends_with?(p, TreePath.new("data")) |> IO.puts
    TreePath.ends_with?(p, TreePath.new("local")) |> IO.puts
    TreePath.ends_with?(p, TreePath.new("objects")) |> IO.puts
    TreePath.ends_with?(p, TreePath.new(["local", "objects"])) |> IO.puts
    TreePath.ends_with?(p, TreePath.append(p, "blah")) |> IO.puts
  end
end
