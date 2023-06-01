import Vectoree.TreePath

alias Vectoree.TreeServer
alias Vectoree.{TreeSource, TreeProcessor, TreeSink}

defmodule Assert do
  def started(result) do
    case result do
      {:ok, pid} -> {:ok, pid}
      {:error, msg} -> raise("Not started (#{msg})")
      _ -> raise("Not started")
    end
  end
end

defmodule CustomTimedSource do
  use Vectoree.TimedTreeSource
  import Vectoree.TreePath
  alias Vectoree.Node

  @impl Vectoree.TimedTreeSource
  def create_tree() do
    for i <- 1..2, into: %{} do
      {~p"node_#{i}", Node.new(:int32, System.system_time(), :nanosecond)}
    end
  end

  @impl Vectoree.TimedTreeSource
  def update_tree(tree) do
    tree
    |> Stream.filter(fn {_, node} -> node.value != :empty end)
    |> Map.new(fn {path, node} -> {path, %Node{node | value: System.system_time()}} end)
  end

  @impl Vectoree.TimedTreeSource
  def first_update() do
    2000
  end

  @impl Vectoree.TimedTreeSource
  def next_update() do
    2000
  end
end

defmodule CustomProcessor do
  use Vectoree.TreeProcessor

  @impl Vectoree.TreeProcessor
  def create_tree() do
    for i <- 1..2, into: %{} do
      {~p"node_#{i}", Node.new(:int32, 0, :none)}
    end
  end

  @impl Vectoree.TreeProcessor
  def handle_notify(_local_mount_path, local_tree, source_mount_path, source_tree) do
    source_tree
    |> Stream.map(fn {k, v} -> "#{TreePath.append(source_mount_path, k)} => #{v}" end)
    |> Enum.each(&IO.inspect(&1, label: " -proc->"))

    new_local_tree =
      source_tree
      |> Stream.each(fn {k, v} -> Map.put(local_tree, k, v) end)
      |> Enum.into(%{})

    new_local_tree
  end
end

defmodule CustomSink do
  use Vectoree.TreeSink

  @impl Vectoree.TreeSink
  def create_state() do
    0
  end

  @impl Vectoree.TreeSink
  def handle_notify(source_mount_path, source_tree, state) do
    source_tree
    |> Enum.map(fn {k, v} -> "#{TreePath.append(source_mount_path, k)} => #{v}" end)
    |> Enum.each(&IO.inspect(&1, label: " -sink->"))

    state + map_size(source_tree)
  end
end

defmodule AmqpSink do
  use Vectoree.TreeSink

  @impl Vectoree.TreeSink
  def create_state() do
    {:ok, connection} = AMQP.Connection.open()
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Exchange.declare(channel, "vectoree", :fanout)

    channel
  end

  @impl Vectoree.TreeSink
  def handle_notify(source_mount_path, source_tree, channel) do
    source_tree
    |> Enum.map(fn {k, v} -> "#{TreePath.append(source_mount_path, k)} => #{v}" end)
    |> Stream.each(&AMQP.Basic.publish(channel, "vectoree", "", &1))
    |> Enum.each(&IO.inspect(&1, label: " -amqp->"))

    channel
  end
end

{:ok, server_pid} = TreeServer.start_link()

TreeServer.start_child_source(server_pid, CustomTimedSource, ~p"data.src1")
|> Assert.started()

TreeServer.start_child_processor(
  server_pid,
  CustomProcessor,
  ~p"data.proc1",
  ~p"data.src1"
)
|> Assert.started()

TreeServer.start_child_sink(server_pid, CustomSink, ~p"data")
|> Assert.started()

TreeServer.start_child_sink(server_pid, AmqpSink, ~p"data.proc1")
|> Assert.started()

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

# ---

TreeServer.query(server_pid, ~p"data")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data'")

# ---

defmodule Receive do
  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.inspect("#{payload}", label: " <-amqp-")
        wait_for_messages(channel)
    end
  end
end

{:ok, connection} = AMQP.Connection.open()
{:ok, channel} = AMQP.Channel.open(connection)

AMQP.Exchange.declare(channel, "vectoree", :fanout)

{:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
AMQP.Queue.bind(channel, queue_name, "vectoree")
AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)

Receive.wait_for_messages(channel)

# ---

Process.sleep(:infinity)
