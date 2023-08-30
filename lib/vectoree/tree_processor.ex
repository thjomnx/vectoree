defmodule Vectoree.TreeProcessor do
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_map :: %{required(tree_path) => any()}

  @callback handle_notify(tree_path, tree_map, tree_path, tree_map) :: tree_map

  @optional_callbacks handle_notify: 4

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeProcessor

      use GenServer
      alias Vectoree.TreeServer
      alias Vectoree.{Tree, TreePath}

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg)
      end

      def handle_query(query_path, local_tree) do
        Map.new(local_tree, fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end)
      end

      def handle_query(query_path, local_tree, chunk_size) do
        path_concatenizer = fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end

        local_tree
        |> Stream.chunk_every(chunk_size)
        |> Enum.map(&Map.new(&1, path_concatenizer))
      end

      def handle_notify(_local_mount_path, local_tree, _source_mount_path, _source_tree) do
        local_tree
      end

      defoverridable Vectoree.TreeProcessor

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

      @impl GenServer
      def handle_cast({:notify, source_mount_path, source_tree}, state) do
        %{mount_path: local_mount_path, local_tree: local_tree} = state

        new_local_tree =
          handle_notify(local_mount_path, local_tree, source_mount_path, source_tree)
          |> Tree.normalize()

        TreeServer.notify(local_mount_path, new_local_tree)

        {:noreply, %{state | mount_path: local_mount_path, local_tree: new_local_tree}}
      end
    end
  end
end
