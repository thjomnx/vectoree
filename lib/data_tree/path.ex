defmodule DataTree.Path do

  @separator "."

  defstruct [segments: []]

  def new(segment) when is_binary(segment), do: init([segment])
  def new(segments) when is_tuple(segments), do: Tuple.to_list(segments) |> Enum.reverse |> init
  def new(segments) when is_list(segments), do: segments |> Enum.reverse |> init

  defp init(segments) do
    %__MODULE__{segments: segments}
  end

  def separator(), do: @separator

  def get_root(path) when is_struct(path, __MODULE__) do
    List.last(path.segments) |> new
  end

  def get_parent(path) when is_struct(path, __MODULE__) do
    case path.segments do
      [_ | []] -> path
      [_ | tail] -> tail |> init
    end
  end

  def append(path, segment) when is_struct(path, __MODULE__) and is_binary(segment) do
    [segment | path.segments] |> init
  end

  def append(path, segments) when is_struct(path, __MODULE__) and is_tuple(segments) do
    append_list(path.segments, Tuple.to_list(segments)) |> init
  end

  def append(path, segments) when is_struct(path, __MODULE__) and is_list(segments) do
    append_list(path.segments, segments) |> init
  end

  defp append_list(segments, []), do: segments
  defp append_list(segments, [head | tail]), do: append_list([head | segments], tail)

  defimpl String.Chars, for: DataTree.Path do
    def to_string(path) do
      Enum.reverse(path.segments) |> Enum.join(DataTree.Path.separator)
    end
  end

end
