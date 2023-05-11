defmodule Vectoree.TreeProcessor do
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
      require Logger
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

      def handle_notify(_, local_tree, _, _) do
        local_tree
      end

      defoverridable Vectoree.TreeProcessor

      @impl GenServer
      def init(init_arg) do
        %{:mount => mount_path, :listen => listen_path} =
          cond do
            is_function(init_arg) -> init_arg.()
            true -> init_arg
          end

        Logger.info(
          "Starting #{__MODULE__} mounted on '#{mount_path}', listening on '#{listen_path}'"
        )

        TreeServer.mount_source(mount_path)
        TreeServer.register_sink(listen_path)

        tree = create_tree() |> Tree.normalize()

        {:ok, {mount_path, tree}}
      end

      @impl GenServer
      def handle_call({:query, path}, _from, {_, tree} = state) do
        concatenizer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

        {:reply, Map.new(tree, concatenizer), state}
      end

      @impl GenServer
      def handle_cast({:notify, source_mount_path, source_tree}, {local_mount_path, local_tree}) do
        Logger.info("Notification received at #{__MODULE__}")

        new_local_tree =
          handle_notify(local_mount_path, local_tree, source_mount_path, source_tree)
          |> Tree.normalize()

        TreeServer.notify(local_mount_path, new_local_tree)

        {:noreply, {local_mount_path, new_local_tree}}
      end
    end
  end
end
