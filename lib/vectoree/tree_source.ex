defmodule Vectoree.TreeSource do
  alias Vectoree.TreePath

  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  @callback create_tree() :: tree_map
  @callback update_tree(tree_map) :: tree_map

  @optional_callbacks create_tree: 0, update_tree: 1

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeSource

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

      defoverridable Vectoree.TreeSource

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

        {:ok, {mount_path, tree}}
      end

      @impl GenServer
      def handle_info(:update, {mount_path, tree}) do
        new_tree = update_tree(tree) |> Tree.normalize()

        TreeSinkRegistry
        |> Registry.select([{{:"$1", :"$2", :"$3"}, [{:"/=", :"$2", self()}], [{{:"$2", :"$3"}}]}])
        |> Stream.filter(fn {_, lpath} -> TreePath.starts_with?(mount_path, lpath) end)
        |> Enum.each(fn {pid, _} -> TreeServer.notify(pid, mount_path, new_tree) end)

        {:noreply, {mount_path, new_tree}}
      end

      @impl GenServer
      def handle_call({:query, path}, _from, {_, tree} = state) do
        concatenizer = fn {local_path, node} -> {TreePath.append(path, local_path), node} end

        {:reply, Map.new(tree, concatenizer), state}
      end
    end
  end

  def query(server, %TreePath{} = path) do
    GenServer.call(server, {:query, path})
  end
end
