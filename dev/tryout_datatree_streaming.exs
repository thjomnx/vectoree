import DataTree.TreePath

alias DataTree.Node

IO.puts("==> DataTree.GenServer.chunked_call")

defmodule StreamServer do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def apply(pid, fun, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, 100)
    :ok = GenServer.call(pid, {:query, chunk_size})
    receive_apply(fun)
  end

  defp receive_apply(fun) do
    receive do
      {:cont, chunk} ->
        fun.(:cont, chunk)
        receive_apply(fun)

      {:ok, []} ->
        :ok

      {:ok, chunk} ->
        fun.(:ok, chunk)
        :ok

      _ ->
        :error
    end
  end

  @impl true
  def init(_) do
    tree =
      for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
        {~p"data.#{i}.#{j}.node_#{k}", Node.new(:int32, System.system_time(), :nanoseconds)}
      end

    state = DataTree.normalize(tree)
    map_size(state) |> IO.inspect(label: "Number of nodes")

    {:ok, state}
  end

  # @impl true
  # def handle_info({:DOWN, _, :process, _, :normal}, state) do
  #   {:noreply, state}
  # end

  @impl true
  def handle_call({:query, chunk_size}, {pid, _} = from, state) do
    GenServer.reply(from, :ok)

    task =
      Task.async(fn ->
        last =
          state
          |> Stream.chunk_every(chunk_size)
          |> Stream.map(fn
            chunk when length(chunk) == chunk_size -> send(pid, {:cont, chunk})
            chunk when length(chunk) < chunk_size -> send(pid, {:ok, chunk})
          end)
          |> Enum.reduce(fn result, _acc -> result end)

        case last do
          {:cont, _} -> send(pid, {:ok, []})
          {:ok, _} -> last
        end
      end)

    Task.await(task, :infinity)

    {:noreply, state}
  end
end

{:ok, pid} = StreamServer.start_link()

fun = fn ctrl, chunk ->
  IO.inspect(length(chunk), label: "Chunk size (#{ctrl})")
end

StreamServer.apply(pid, fun, chunk_size: 12345)
