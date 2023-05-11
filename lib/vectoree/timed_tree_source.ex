defmodule Vectoree.TimedTreeSource do
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  @callback create_tree() :: tree_map
  @callback update_tree(tree_map) :: tree_map

  @callback first_update() :: integer()
  @callback next_update() :: integer()

  @optional_callbacks create_tree: 0, update_tree: 1, first_update: 0, next_update: 0

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TimedTreeSource

      use GenServer
      require Logger
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

      def first_update() do
        5000
      end

      def next_update() do
        5000
      end

      defoverridable Vectoree.TimedTreeSource

      @impl GenServer
      def init(init_arg) do
        {:mount, mount_path} =
          cond do
            is_function(init_arg) -> init_arg.()
            true -> init_arg
          end

        Logger.info("Starting #{__MODULE__} on '#{mount_path}'")

        TreeServer.mount_source(mount_path)

        tree = create_tree() |> Tree.normalize()

        Process.send_after(self(), :update, first_update())

        {:ok, {mount_path, tree}}
      end

      @impl GenServer
      def handle_info(:update, {mount_path, tree}) do
        new_tree = update_tree(tree) |> Tree.normalize()
        TreeServer.notify(mount_path, new_tree)

        Process.send_after(self(), :update, next_update())

        {:noreply, {mount_path, new_tree}}
      end

      @impl GenServer
      def handle_call({:query, path}, _from, {_, tree} = state) do
        concatenizer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

        {:reply, Map.new(tree, concatenizer), state}
      end
    end
  end
end