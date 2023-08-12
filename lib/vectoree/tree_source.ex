defmodule Vectoree.TreeSource do
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_map :: %{required(tree_path) => any()}

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer
      alias Vectoree.{Tree, TreePath}

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg, unquote(Macro.escape(opts)))
      end

      def handle_query(query_path, tree) do
        Map.new(tree, fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end)
      end

      @impl GenServer
      def handle_call({:query, query_path, opts}, {pid, _} = from, %{local_tree: tree} = state) do
        chunk_size = Keyword.get(opts, :chunk_size, 0)
        IO.inspect(chunk_size, label: "chunk_size")

        GenServer.reply(from, :ok)
        send(pid, {:ok, handle_query(query_path, tree)})

        {:noreply, state}
      end
    end
  end
end
