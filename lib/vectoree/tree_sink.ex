defmodule Vectoree.TreeSink do
  alias Vectoree.TreePath
  @type tree_path :: Vectoree.TreePath.t()
  @type tree_node :: Vectoree.Node.t()
  @type tree_map :: %{required(tree_path) => tree_node}

  @callback handle_notify(tree_path, tree_map, any()) :: any()

  @optional_callbacks handle_notify: 3

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeSink

      use GenServer
      require Logger
      alias Vectoree.TreeServer
      alias Vectoree.TreePath

      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg)
      end

      def handle_notify(_, _, state) do
        state
      end

      defoverridable Vectoree.TreeSink

      @impl GenServer
      def init(init_arg) do
        %{listen: listen_path} = Vectoree.TreeSink.get_tree_args(init_arg)

        TreeServer.register_sink(listen_path)

        {:ok, 0}
      end

      @impl GenServer
      def handle_cast({:notify, source_mount_path, source_tree}, state) do
        Logger.info("Notification received at #{__MODULE__}")

        new_state = handle_notify(source_mount_path, source_tree, state)

        {:noreply, new_state}
      end
    end
  end

  def get_tree_args(%{listen: %TreePath{}} = map) do
    Map.take(map, [:listen])
  end

  def get_tree_args(args) when is_function(args) do
    args.() |> get_tree_args()
  end
end
