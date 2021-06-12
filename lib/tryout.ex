defmodule Tryout do
  use Application

  alias DataTree.{Parameter, Path}

  def start(_type, _args) do
    run_proto()
    {:ok, self()}
  end

  def run_proto do
    DataTree.start_link(name: :ptree)

    {:ok, data} = DataTree.put(:ptree, Parameter.new([], "data"))
    {:ok, local} = DataTree.put(:ptree, Parameter.new(["data"], "local"))

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    {:ok, ticks} = DataTree.put(:ptree, Parameter.new(["data", "local"], "ticks", :int32, timestamp, :milliseconds))

    IO.inspect(data)
    IO.inspect(local)
    IO.inspect(ticks)

    IO.puts(ticks.value)

    Enum.map(
      1..9999,
      fn i ->
        name = "param" <> Integer.to_string(i)
        DataTree.put(:ptree, Parameter.new(["data"], name))
      end
    )

    DataTree.lookup(:ptree, ["data", "param23"]) |> IO.inspect

    p = Path.new({"data", "local", "objects"})
    IO.inspect(p)

    Path.parent(p) |> IO.puts
    Path.append(p, "myClock") |> IO.puts
    Path.append(p, ["remote", "peer", "bomb28"]) |> IO.puts
    Path.append(p, {"remote", "peer", "studio54"}) |> IO.puts
    Path.base(p) |> IO.puts
    Path.new("data") |> Path.parent |> IO.puts
    Path.sibling(p, "monitors") |> IO.puts
    Path.new(["", "data", "", "", "", "raw", "", "proj.x"]) |> IO.puts

    IO.puts("-------------------------")

    Path.starts_with?(p, Path.parent(p)) |> IO.puts
    Path.starts_with?(p, Path.new("data")) |> IO.puts
    Path.starts_with?(p, Path.new("local")) |> IO.puts
    Path.starts_with?(p, Path.new("objects")) |> IO.puts
    Path.starts_with?(p, Path.new({"data", "remote"})) |> IO.puts
    Path.starts_with?(p, Path.append(p, "blah")) |> IO.puts

    IO.puts("-------------------------")

    Path.ends_with?(p, Path.parent(p)) |> IO.puts
    Path.ends_with?(p, Path.new("data")) |> IO.puts
    Path.ends_with?(p, Path.new("local")) |> IO.puts
    Path.ends_with?(p, Path.new("objects")) |> IO.puts
    Path.ends_with?(p, Path.new({"local", "objects"})) |> IO.puts
    Path.ends_with?(p, Path.append(p, "blah")) |> IO.puts
  end
end
