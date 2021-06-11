defmodule DataTree.Tryout do
  use Application
  alias DataTree.Parameter

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

    DataTree.lookup(:ptree, ["data", "param23"])
  end
end
