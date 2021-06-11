defmodule DataTree.Path do

  defstruct [segments: []]

  def new(segment) when is_binary(segment), do: init([segment])
  def new(segments) when is_tuple(segments), do: Tuple.to_list(segments) |> Enum.reverse |> init
  def new(segments) when is_list(segments), do: segments |> Enum.reverse |> init

  defp init(segments) do
    %__MODULE__{segments: segments}
  end

  def get_parent(path) when is_struct(path, __MODULE__) do
    tl(path.segments) |> init
  end

  def append(path, segment) when is_struct(path, __MODULE__) and is_binary(segment) do
    [segment | path.segments] |> init
  end

  def append(path, segments) when is_tuple(segments) do
    list = Tuple.to_list(segments) |> Enum.reverse
    list ++ path.segments |> init
  end

end
