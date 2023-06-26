defmodule Vectoree.TreeSource do
  alias Vectoree.TreePath
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  @callback create_tree() :: tree_map
  @callback update_tree(tree_map) :: tree_map

  @optional_callbacks create_tree: 0, update_tree: 1

  alias Vectoree.TreePath

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeSource

      use GenServer
      alias Vectoree.TreeServer
      alias Vectoree.{Tree, TreePath}

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg, unquote(Macro.escape(opts)))
      end

      def create_tree() do
        Map.new()
      end

      def update_tree(tree) do
        tree
      end

      def handle_query(query_path, local_tree) do
        Map.new(local_tree, fn {local_path, node} ->
          {TreePath.append(query_path, local_path), node}
        end)
      end

      defoverridable Vectoree.TreeSource

      @impl GenServer
      def init(init_arg) do
        %{mount: mount_path} = TreeServer.args2info(init_arg)

        TreeServer.mount_source(mount_path)

        tree = create_tree() |> Tree.normalize()

        {:ok, %{mount_path: mount_path, local_tree: tree}}
      end

      @impl GenServer
      def handle_info(:update, %{mount_path: mount_path, local_tree: tree} = state) do
        new_tree = update_tree(tree) |> Tree.normalize()
        TreeServer.notify(mount_path, new_tree)

        {:noreply, %{state | mount_path: mount_path, local_tree: new_tree}}
      end

      @impl GenServer
      def handle_call({:query, query_path}, _from, %{local_tree: local_tree} = state) do
        {:reply, handle_query(query_path, local_tree), state}
      end
    end
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end
end
