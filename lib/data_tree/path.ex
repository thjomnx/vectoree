defmodule DataTree.Path do

  @separator "."
  @separator_replacement "_" <> Base.encode16(@separator, case: :lower)

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

  defp init_raw(segment) when is_binary(segment) do
    %__MODULE__{segments: [segment]}
  end

  def normalize(segment) when is_binary(segment) do
    String.replace(segment, @separator, @separator_replacement)
  end

  def normalize(segments) when is_list(segments) do
    segments
      |> Stream.filter(&(String.length(&1) > 0))
      |> Enum.map(&(String.replace(&1, @separator, @separator_replacement)))
  end

  def separator(), do: @separator

  def root(%__MODULE__{segments: segments}) do
    List.last(segments) |> init_raw
  end

  def parent(%__MODULE__{segments: segments} = path) do
    case segments do
      [] -> path
      [_ | []] -> path
      [_ | tail] -> tail |> init
    end
  end

  def base(%__MODULE__{segments: segments} = path) do
    case segments do
      [head | _] -> head |> init_raw
      _ -> path
    end
  end

  def basename(%__MODULE__{segments: segments}) do
    case segments do
      [head | _] -> head
      _ -> ""
    end
  end

  def sibling(%__MODULE__{} = path, segment) when is_binary(segment) do
    [segment | parent(path).segments] |> init
  end

  def append(%__MODULE__{segments: segments}, segment) when is_binary(segment) do
    [segment | segments] |> init
  end

  def append(%__MODULE__{} = path, segments) when is_tuple(segments) do
    append_list(path.segments, Tuple.to_list(segments)) |> init
  end

  def append(%__MODULE__{} = path, segments) when is_list(segments) do
    append_list(path.segments, segments) |> init
  end

  defp append_list(segments, []), do: segments
  defp append_list(segments, [head | tail]), do: append_list([head | segments], tail)

  def starts_with?(%__MODULE__{segments: segments}, prefix) do
    fun = &(List.starts_with?(segments |> Enum.reverse, &1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_tuple(prefix) -> fun.(Tuple.to_list(prefix))
      is_list(prefix) -> fun.(prefix)
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse)
    end
  end

  def ends_with?(%__MODULE__{segments: segments}, suffix) do
    fun = &(List.starts_with?(segments, &1))

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
