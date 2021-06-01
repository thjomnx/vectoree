defmodule DataTree.Tryout do
  alias DataTree.Parameter

  def test do
    DataTree.start_link(name: :ptree)

    {:ok, data} = DataTree.put(:ptree, "data", Parameter.new("data"))

    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    {:ok, ticks} = DataTree.put(:ptree, "data.ticks", Parameter.new("ticks", :int32, timestamp, :milliseconds))

    IO.inspect(data)
    IO.inspect(ticks)

    IO.puts(ticks.value)
  end
end
