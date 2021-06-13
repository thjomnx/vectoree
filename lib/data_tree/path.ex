defmodule DataTree.Path do

  @separator "."
  @separator_replacement "_"

  defstruct [segments: []]

  def new(segment) when is_binary(segment), do: [segment] |> init
  def new(segments) when is_tuple(segments), do: Tuple.to_list(segments) |> init_reversed
  def new(segments) when is_list(segments), do: segments |> init_reversed

  defp init(segments) do
    %__MODULE__{segments: segments |> normalize}
  end

  defp init_reversed(segments) do
    %__MODULE__{segments: segments |> normalize |> Enum.reverse}
  end

  defp normalize(segments) do
    segments
      |> Stream.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.replace(&1, @separator, @separator_replacement)))
  end

  def separator(), do: @separator

  def base(path) when is_struct(path, __MODULE__) do
    List.last(path.segments) |> new
  end

  def parent(path) when is_struct(path, __MODULE__) do
    case path.segments do
      [_ | []] -> path
      [_ | tail] -> tail |> init
    end
  end

  def sibling(path, segment) when is_struct(path, __MODULE__) and is_binary(segment) do
    [segment | parent(path).segments] |> init
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

  def starts_with?(path, prefix) when is_struct(path, __MODULE__) do
    fun = &(List.starts_with?(path.segments |> Enum.reverse, &1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_tuple(prefix) -> fun.(Tuple.to_list(prefix))
      is_list(prefix) -> fun.(prefix)
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse)
    end
  end

  def ends_with?(path, suffix) when is_struct(path, __MODULE__) do
    fun = &(List.starts_with?(path.segments, &1))

    cond do
      is_binary(suffix) -> fun.([suffix])
      is_tuple(suffix) -> fun.(Tuple.to_list(suffix))
      is_list(suffix) -> fun.(suffix)
      is_struct(suffix, __MODULE__) -> fun.(suffix.segments)
    end
  end

  defimpl String.Chars, for: DataTree.Path do
    def to_string(path) do
      Enum.reverse(path.segments) |> Enum.join(DataTree.Path.separator)
    end
  end
end
