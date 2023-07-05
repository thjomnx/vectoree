import Vectoree.TreePath
alias Vectoree.TreePath

defmodule Payload do
  defstruct [
    :type,
    :value,
    :unit,
    status: 0,
    modified: 0
  ]

  def new(
        type \\ :none,
        value \\ :empty,
        unit \\ :none,
        status \\ 0,
        modified \\ 0
      ) do
    %Payload{
      type: type,
      value: value,
      unit: unit,
      status: status,
      modified: modified
    }
  end

  def update_value(tree, %TreePath{} = path, value) do
    update(tree, path, fn v -> %Payload{v | value: value, modified: System.system_time()} end)
  end

  defp update(tree, %TreePath{} = path, fun) do
    Map.update(tree, path, &Payload.new/0, fun)
  end
end

tree_small =
  for i <- 1..10, j <- 1..10, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Payload.new()}
  end

tree_medium =
  for i <- 1..100, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Payload.new()}
  end

tree_large =
  for i <- 1..1000, j <- 1..100, k <- 1..20, into: %{} do
    {~p"data.#{i}.#{j}.node_#{k}", Payload.new()}
  end

Benchee.run(
  %{
    "update_value" => fn {tree, path} -> Payload.update_value(tree, path, 12345) end
  },
  inputs: %{
    "small" => {tree_small, ~p"data.3.4.node_11"},
    "medium" => {tree_medium, ~p"data.23.42.node_11"},
    "large" => {tree_large, ~p"data.2323.42.node_11"}
  }
)
