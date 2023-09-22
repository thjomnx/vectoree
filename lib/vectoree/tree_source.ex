defmodule Vectoree.TreeSource do
  @moduledoc """
  A behaviour module for implementing a server, which maintains a local tree
  (key-value map) as its internal state. A source is supposed to be mounted on a
  `TreeServer` at a path via the `TreeServer.mount_source/1` function, normally
  during the `c:init/1` callback. It is then supposed to do two things:

  - Reply to query requests by returning the local tree in a mounted state (done
    by the `handle_query` functions in this module)
  - Notify the hosting `TreeServer` about updates in the local tree via the
    `TreeServer.notify/2` function
  """

  @type tree_path :: Vectoree.TreePath.t()
  @type tree_map :: %{required(tree_path) => any()}

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer
      alias Vectoree.{Tree, TreePath}

      @doc false
      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg, unquote(Macro.escape(opts)))
      end

      @doc false
      def handle_query(query_path, local_tree) do
        Map.new(local_tree, fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end)
      end

      @doc false
      def handle_query(query_path, local_tree, chunk_size) do
        path_concatenizer = fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end

        local_tree
        |> Stream.chunk_every(chunk_size)
        |> Enum.map(&Map.new(&1, path_concatenizer))
      end

      @impl GenServer
      def handle_call({:query, query_path, opts}, {pid, _} = from, %{local_tree: tree} = state) do
        chunk_size = Keyword.get(opts, :chunk_size, 0)

        GenServer.reply(from, :ok)

        if chunk_size == 0 do
          send(pid, {:ok, handle_query(query_path, tree)})
        else
          chunked_tree = handle_query(query_path, tree, chunk_size)

          last =
            chunked_tree
            |> Stream.map(fn
              chunk when map_size(chunk) == chunk_size -> send(pid, {:cont, chunk})
              chunk when map_size(chunk) < chunk_size -> send(pid, {:ok, chunk})
            end)
            |> Enum.reduce(fn result, _acc -> result end)

          case last do
            {:cont, _} -> send(pid, {:ok, %{}})
            {:ok, _} -> last
          end
        end

        {:noreply, state}
      end
    end
  end
end
