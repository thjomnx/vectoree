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

      def handle_query(query_path, local_tree) do
        Map.new(local_tree, fn {local_path, payload} ->
          {TreePath.append(query_path, local_path), payload}
        end)
      end

      @impl GenServer
      def handle_call({:query, query_path, opts}, _from, %{local_tree: local_tree} = state) do
        {:reply, handle_query(query_path, local_tree), state}
      end
    end
  end
end
