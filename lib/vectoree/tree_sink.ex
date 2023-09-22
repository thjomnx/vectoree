defmodule Vectoree.TreeSink do
  @moduledoc """
  A behaviour module for implementing a server, which reacts on changes on
  another part of the (global) tree. A sink is supposed to be registered on one
  or more paths on a `TreeServer` via the `TreeServer.register_sink/1` function,
  at any time.

  It is then supposed to do one thing:

  - React to notifications (casts) received from the hosting `TreeServer` via
  the `handle_notify` functions
  """

  @type tree_path :: Vectoree.TreePath.t()
  @type tree_map :: %{required(tree_path) => any()}

  @callback handle_notify(tree_path, tree_map, any()) :: any()

  @optional_callbacks handle_notify: 3

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Vectoree.TreeSink

      use GenServer
      alias Vectoree.TreeServer
      alias Vectoree.TreePath

      @doc false
      def start_link(init_arg) do
        GenServer.start_link(__MODULE__, init_arg)
      end

      @doc false
      def handle_notify(_, _, state) do
        state
      end

      defoverridable Vectoree.TreeSink

      @impl GenServer
      def handle_cast({:notify, source_mount_path, source_tree}, state) do
        new_state = handle_notify(source_mount_path, source_tree, state)

        {:noreply, new_state}
      end
    end
  end
end
