defmodule Profiler do
  import ExProf.Macro
  import DataTree.{Node, TreePath}

  alias DataTree.NodeTable

  def run_all do
    profile do
      NodeTable.new(:ptree)

      for i <- 1..100, j <- 1..100, k <- 1..20 do
        NodeTable.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
      end

      case NodeTable.subtree(:ptree, ~p"data") do
        {:ok, sub} ->
          length(sub) |> IO.puts()

        {:error, reason} ->
          IO.puts(reason)
      end

      path = ~p"data.23.42.node_11"

      for i <- 1..10_000_000 do
        NodeTable.update_value(:ptree, path, i)
      end
    end
  end

  def run_insert do
    NodeTable.new(:ptree, :public)

    profile do
      for i <- 1..100, j <- 1..100, k <- 1..20 do
        NodeTable.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
      end
    end
  end

  def run_subtree do
    NodeTable.new(:ptree, :public)

    for i <- 1..100, j <- 1..100, k <- 1..20 do
      NodeTable.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
    end

    profile do
      case NodeTable.subtree(:ptree, ~p"data") do
        {:ok, sub} ->
          length(sub) |> IO.puts()

        {:error, reason} ->
          IO.puts(reason)
      end
    end
  end

  def run_update_value do
    NodeTable.new(:ptree, :public)

    for i <- 1..100, j <- 1..100, k <- 1..20 do
      NodeTable.insert(:ptree, ~n"data.#{i}.#{j}.node_#{k}")
    end

    path = ~p"data.23.42.node_11"

    profile do
      for i <- 1..10_000_000 do
        NodeTable.update_value(:ptree, path, i)
      end
    end
  end
end

# Profiler.run_all()
Profiler.run_insert()
# Profiler.run_subtree()
# Profiler.run_update_value()
