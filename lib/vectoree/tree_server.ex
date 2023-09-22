defmodule Vectoree.TreeServer do
  @moduledoc """
  A module for running a `GenServer` process, which acts as a central hosting
  point of a "tree" (key-value map). The server can host a local part of a
  (typically static) tree, which forms the base for other subtrees, which are
  mounted as concurrent processes of type `TreeSource` and `TreeProcessor` on
  the central server. Concurrent processes of type `TreeProcessor` and
  `TreeSink` can be registered on the central server to receive updates on
  subtrees via casts.

  A `TreeServer` can be started in the usual way, i.e. via the
  `TreeServer.start_link/1` function or as part of a supervision tree. The
  server itself spawns a group of `DynamicSupervisor` processes for the
  supervision of sources, processors and sinks.

  There can be only one `TreeServer` process being alive on a single ERTS node.
  """

  use GenServer
  alias Vectoree.{Tree, TreePath}

  @type path :: %TreePath{}

  @doc """
  Accepts a map and returns a tailored map including only the keys `:mount` and
  `:listen`, depending on what is required.

  ## Examples

      iex> Vectoree.TreeServer.args2info(%{mount: ~p"a.b.c", foo: :bar, listen: ~p"a.b"})
      %{mount: ~p"a.b.c", listen: ~p"a.b"}

      iex> Vectoree.TreeServer.args2info(%{mount: ~p"a.b.c", foo: :bar})
      %{mount: ~p"a.b.c"}

      iex> Vectoree.TreeServer.args2info(%{foo: :bar, listen: ~p"a.b"})
      %{listen: ~p"a.b"}

      iex> Vectoree.TreeServer.args2info(fn -> %{foo: :bar, listen: ~p"a.b"} end)
      %{listen: ~p"a.b"}
  """
  @spec args2info(%{mount: path, listen: path}) :: %{mount: path, listen: path}
  def args2info(%{mount: %TreePath{}, listen: %TreePath{}} = map) do
    Map.take(map, [:mount, :listen])
  end

  @spec args2info(%{mount: path}) :: %{mount: path}
  def args2info(%{mount: %TreePath{}} = map) do
    Map.take(map, [:mount])
  end

  @spec args2info(%{listen: path}) :: %{listen: path}
  def args2info(%{listen: %TreePath{}} = map) do
    Map.take(map, [:listen])
  end

  @spec args2info(fun()) :: %{mount: path, listen: path}
  def args2info(args) when is_function(args) do
    args.() |> args2info()
  end

  @doc """
  Starts a new server process linked to the current process. See
  `GenServer.start_link` for detailed documentation.

  The `opts` keyword list may contain a `:tree` item with a value of type map,
  which is used as the base tree for the server.

  ## Examples

      Vectoree.TreeServer.start_link(tree: %{~p"a.b" => :payload})
      {:ok, pid}
  """
  @spec start_link(tree: map()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    tree = Keyword.get(opts, :tree, %{})

    unless is_map(tree) do
      raise("Keyword item :tree does not carry a map")
    end

    GenServer.start_link(__MODULE__, tree, opts)
  end

  @doc """
  Starts a source via the given `TreeServer` denoted by the given module. A path
  must be given at which the sources' internal tree is mounted on the base tree.

  ## Examples

      Vectoree.TreeServer.start_source(server_pid, CustomSource, ~p"a.b.s0")
      {:ok, pid}
  """
  @spec start_source(GenServer.server(), module(), path) :: GenServer.on_start()
  def start_source(server, module, %TreePath{} = mount_path) do
    GenServer.call(server, {:add_source, module, mount_path})
  end

  @doc """
  Stops a source via the given `TreeServer` denoted by its PID.

  ## Examples

      Vectoree.TreeServer.stop_source(server_pid, source_pid)
      :ok
  """
  @spec stop_source(GenServer.server(), pid()) :: :ok | {:error, :not_found}
  def stop_source(server, pid) do
    GenServer.call(server, {:remove_source, pid})
  end

  @doc """
  Starts a processor via the given `TreeServer` denoted by the given module.
  Paths must be given at which the processor' internal tree is mounted on the
  base tree and at which the processor shall listen for updates.

  ## Examples

      Vectoree.TreeServer.start_processor(server_pid, CustomSource, ~p"a.b.p0", ~p"a.b.c.d")
      {:ok, pid}
  """
  @spec start_processor(GenServer.server(), module(), path, path) :: GenServer.on_start()
  def start_processor(server, module, %TreePath{} = mount_path, %TreePath{} = listen_path) do
    GenServer.call(server, {:add_processor, module, mount_path, listen_path})
  end

  @doc """
  Stops a processor via the given `TreeServer` denoted by its PID.

  ## Examples

      Vectoree.TreeServer.stop_processor(server_pid, source_pid)
      :ok
  """
  @spec stop_processor(GenServer.server(), pid()) :: :ok | {:error, :not_found}
  def stop_processor(server, pid) do
    GenServer.call(server, {:remove_processor, pid})
  end

  @doc """
  Starts a sink via the given `TreeServer` denoted by the given module. A path
  must be given at which the sink shall listen for updates.

  ## Examples

      Vectoree.TreeServer.start_sink(server_pid, CustomSource, ~p"a.b.p0", ~p"a.b.c.d")
      {:ok, pid}
  """
  @spec start_sink(GenServer.server(), module(), path) :: GenServer.on_start()
  def start_sink(server, module, %TreePath{} = listen_path) do
    GenServer.call(server, {:add_sink, module, listen_path})
  end

  @doc """
  Stops a sink via the given `TreeServer` denoted by its PID.

  ## Examples

      Vectoree.TreeServer.stop_processor(server_pid, source_pid)
      :ok
  """
  @spec stop_sink(GenServer.server(), pid()) :: :ok | {:error, :not_found}
  def stop_sink(server, pid) do
    GenServer.call(server, {:remove_sink, pid})
  end

  @doc """
  Mounts the calling process as a source at the given path.
  """
  @spec mount_source(path) :: {:ok, pid} | {:error, {:already_registered, pid}}
  def mount_source(%TreePath{} = path) do
    Registry.register(TreeSourceRegistry, :source, path)
  end

  @doc """
  Registers the calling process as a sink (listener) at the given path.
  """
  @spec register_sink(path) :: {:ok, pid} | {:error, {:already_registered, pid}}
  def register_sink(%TreePath{} = path) do
    Registry.register(TreeSinkRegistry, :sink, path)
  end

  @doc """
  Queries the `TreeServer` at the given path and returns the aggregated tree of
  path-payload pairs. The aggregated tree is assembled by passing the query on
  to all sources and processors, which are mounted on the server.

  The `opts` keyword list may contain a `:chunk_size` item with an integer,
  which is used for chunking the replies coming from all sources and processors.
  This can be useful in case of large trees (millions of entries).

  ## Examples

      Vectoree.TreeServer.query(server_pid, ~p"a.b")
      #=> %{...}

      Vectoree.TreeServer.query(server_pid, ~p"a", chunk_size: 1000)
      #=> %{...}
  """
  @spec query(GenServer.server(), path, chunk_size: integer()) :: map()
  def query(server, %TreePath{} = path, opts \\ []) do
    fun = fn _ctrl, chunk, acc -> Map.merge(acc, chunk) end
    query_apply(server, path, %{}, fun, opts)
  end

  @doc """
  Queries the `TreeServer` at the given path and applies a custom function on
  each replied chunk and by using given accumulator (if required).

  The function arguments are

  - the control atom of the chunk, one of
    - `:cont` indicating more replies to come
    - `:ok` indicating the last chunk
  - the chunk (a map)
  - the accumulator

  ## Examples

      fun = fn _ctrl, chunk, acc -> Map.merge(acc, chunk) end
      Vectoree.TreeServer.query_apply(server_pid, ~p"a", %{}, fun, chunk_size: 1000)
      #=> %{...}
  """
  @spec query_apply(GenServer.server(), path, any(), fun(), chunk_size: integer()) :: any()
  def query_apply(server, %TreePath{} = path, acc, fun, opts \\ []) do
    :ok = GenServer.call(server, {:query, path, opts})
    receive_apply(acc, fun)
  end

  defp receive_apply(acc, fun) do
    receive do
      {:cont, chunk} when is_map(chunk) ->
        new_acc = fun.(:cont, chunk, acc)
        receive_apply(new_acc, fun)

      {:ok, chunk} when is_map(chunk) ->
        fun.(:ok, chunk, acc)

      _ ->
        :error
    end
  end

  @doc """
  Broadcasts a notification about a changed tree at the given path.

  `notify/2` computes an enumeration of all registered listeners for which the
  notification is relevant and then uses `notify/3` to broadcast the
  notification to each particular process.
  """
  @spec notify(path, map()) :: :ok
  def notify(%TreePath{} = path, tree) do
    TreeSinkRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [{:"/=", :"$2", self()}], [{{:"$2", :"$3"}}]}])
    |> Stream.filter(fn {_, lpath} -> TreePath.starts_with?(path, lpath) end)
    |> Enum.each(fn {pid, _} -> notify(pid, path, tree) end)
  end

  @spec notify(GenServer.server(), path, map()) :: :ok
  def notify(server, %TreePath{} = path, tree) when is_map(tree) do
    GenServer.cast(server, {:notify, path, tree})
  end

  @impl true
  def init(tree) do
    children = [
      {Registry, keys: :duplicate, name: TreeSourceRegistry},
      {Registry, keys: :duplicate, name: TreeSinkRegistry},
      {DynamicSupervisor, name: TreeSourceSupervisor},
      {DynamicSupervisor, name: TreeProcessorSupervisor},
      {DynamicSupervisor, name: TreeSinkSupervisor}
    ]

    {:ok, supervisor_pid} = Supervisor.start_link(children, strategy: :one_for_one)

    {:ok, %{supervisor: supervisor_pid, tree: tree}}
  end

  @impl true
  def handle_call({:add_source, module, mount_path}, _from, %{tree: tree} = state) do
    unless mount_conflict?(mount_path) do
      result =
        DynamicSupervisor.start_child(
          TreeSourceSupervisor,
          {module, %{mount: mount_path}}
        )

      case result do
        {:ok, _} ->
          {:reply, result, %{state | tree: Tree.normalize(tree, mount_path)}}

        _ ->
          {:reply, result, state}
      end
    else
      {:reply, {:error, "Mount conflict for path '#{mount_path}'"}, state}
    end
  end

  @impl true
  def handle_call({:remove_source, pid}, _from, state) do
    result = DynamicSupervisor.terminate_child(TreeSourceSupervisor, pid)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_processor, module, mount_path, listen_path}, _from, %{tree: tree} = state) do
    unless mount_conflict?(mount_path) do
      result =
        DynamicSupervisor.start_child(
          TreeProcessorSupervisor,
          {module, %{mount: mount_path, listen: listen_path}}
        )

      case result do
        {:ok, _} ->
          {:reply, result, %{state | tree: Tree.normalize(tree, mount_path)}}

        _ ->
          {:reply, result, state}
      end
    else
      {:reply, {:error, "Mount conflict for path '#{mount_path}'"}, state}
    end
  end

  @impl true
  def handle_call({:remove_processor, pid}, _from, state) do
    result = DynamicSupervisor.terminate_child(TreeProcessorSupervisor, pid)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:add_sink, module, listen_path}, _from, state) do
    result =
      DynamicSupervisor.start_child(
        TreeSinkSupervisor,
        {module, %{listen: listen_path}}
      )

    {:reply, result, state}
  end

  @impl true
  def handle_call({:remove_sink, pid}, _from, state) do
    result = DynamicSupervisor.terminate_child(TreeSinkSupervisor, pid)

    {:reply, result, state}
  end

  @impl true
  def handle_call({:query, path, opts}, {pid, _} = from, %{tree: tree} = state) do
    chunk_size = Keyword.get(opts, :chunk_size, 0)

    GenServer.reply(from, :ok)

    filtered_tree =
      tree
      |> Enum.filter(fn {p, _} -> TreePath.starts_with?(p, path) end)
      |> Map.new()

    if chunk_size == 0 do
      send(pid, {:cont, filtered_tree})
    else
      filtered_tree
      |> Stream.chunk_every(chunk_size)
      |> Stream.map(&Map.new/1)
      |> Enum.each(fn chunk -> send(pid, {:cont, chunk}) end)
    end

    TreeSourceRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$2", :"$3"}}]}])
    |> Stream.filter(fn {_, mpath} -> TreePath.starts_with?(mpath, path) end)
    |> Task.async_stream(fn {mpid, mpath} ->
      query_apply(mpid, mpath, nil, fn _, chunk, _ -> send(pid, {:cont, chunk}) end, opts)
    end)
    |> Stream.run()

    send(pid, {:ok, %{}})

    {:noreply, state}
  end

  defp mount_conflict?(path) do
    TreeSourceRegistry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$2", :"$3"}}]}])
    |> Enum.any?(fn {_, mpath} -> TreePath.starts_with?(path, mpath) end)
  end
end
