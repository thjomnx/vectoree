defmodule Vectoree.TreeProcessor do
  alias Vectoree.TreePath
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  @callback create_tree() :: tree_map
  @callback update_tree(tree_map) :: tree_map
  @callback handle_notify(tree_path, tree_map, tree_path, tree_map) :: tree_map

  @optional_callbacks create_tree: 0, update_tree: 1, handle_notify: 4

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeProcessor

      use GenServer
      alias Vectoree.TreeServer
      alias Vectoree.{Node, Tree, TreePath}

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg)
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

      def handle_notify(_local_mount_path, local_tree, _source_mount_path, _source_tree) do
        local_tree
      end

      defoverridable Vectoree.TreeProcessor

      @impl GenServer
      def init(init_arg) do
        %{mount: mount_path, listen: listen_path} = TreeServer.args2info(init_arg)

        TreeServer.mount_source(mount_path)
        TreeServer.register_sink(listen_path)

        tree = create_tree() |> Tree.normalize()

        {:ok, %{mount_path: mount_path, local_tree: tree}}
      end

      @impl GenServer
      def handle_call({:query, query_path}, _from, %{local_tree: tree} = state) do
        {:reply, handle_query(query_path, tree), state}
      end

      @impl GenServer
      def handle_cast(
            {:notify, source_mount_path, source_tree},
            %{
              mount_path: local_mount_path,
              local_tree: local_tree
            } = state
          ) do
        new_local_tree =
          handle_notify(local_mount_path, local_tree, source_mount_path, source_tree)
          |> Tree.normalize()

        TreeServer.notify(local_mount_path, new_local_tree)

        {:noreply, %{state | mount_path: local_mount_path, local_tree: new_local_tree}}
      end
    end
  end
end
