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

{:ok, server_pid} = TreeServer.start_link()

TreeServer.start_child_source(server_pid, TreeSource, ~p"data.src1")
|> Assert.started()

TreeServer.start_child_processor(server_pid, TreeProcessor, ~p"data.proc1", ~p"data.src1")
|> Assert.started()

TreeServer.start_child_sink(server_pid, TreeSink, ~p"data")
|> Assert.started()

# ---

DynamicSupervisor.count_children(TreeSourceSupervisor) |> IO.inspect(label: "sources")
DynamicSupervisor.count_children(TreeProcessorSupervisor) |> IO.inspect(label: "processors")
DynamicSupervisor.count_children(TreeSinkSupervisor) |> IO.inspect(label: "sinks")

# ---

TreeServer.query(server_pid, ~p"data")
|> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
|> IO.inspect(label: "query on 'data'")

Process.sleep(:infinity)
