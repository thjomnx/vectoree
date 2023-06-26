defmodule Vectoree.TreeSource do
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer
      alias Vectoree.{Tree, TreePath}

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg, unquote(Macro.escape(opts)))
      end

      def handle_query(query_path, local_tree) do
        Map.new(local_tree, fn {local_path, node} ->
          {TreePath.append(query_path, local_path), node}
        end)
      end

      @impl GenServer
      def handle_call({:query, query_path}, _from, %{local_tree: local_tree} = state) do
        {:reply, handle_query(query_path, local_tree), state}
      end
    end
  end
end
