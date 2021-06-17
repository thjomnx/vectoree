defmodule DataTree.TreePath do

  @separator "."
  @separator_replacement "_" <> Base.encode16(@separator, case: :lower)

  defstruct [segments: []]

  def new(segment) when is_binary(segment), do: [segment] |> init
  def new(segments) when is_list(segments), do: segments |> init_reversed

  def sigil_t(term, []) when is_binary(term) do
    String.split(term, @separator) |> new
  end

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

  def level(%__MODULE__{segments: segments}) do
    length(segments)
  end

  def root(%__MODULE__{segments: segments}) do
    List.last(segments) |> init_raw
  end

  def parent(%__MODULE__{segments: segments} = path) do
    case segments do
      [_ | tail] -> tail |> init
      _ -> path
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

  def append(%__MODULE__{} = path, segments) when is_list(segments) do
    append_list(path.segments, segments) |> init
  end

  defp append_list(segments, []), do: segments
  defp append_list(segments, [head | tail]), do: append_list([head | segments], tail)

  def starts_with?(%__MODULE__{segments: segments}, prefix) do
    fun = &(segments |> Enum.reverse |> List.starts_with?(&1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_list(prefix) -> fun.(prefix)
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse)
    end
  end

  def ends_with?(%__MODULE__{segments: segments}, suffix) do
    fun = &(List.starts_with?(segments, &1))

    cond do
      is_binary(suffix) -> fun.([suffix])
      is_list(suffix) -> fun.(suffix)
      is_struct(suffix, __MODULE__) -> fun.(suffix.segments)
    end
  end

  defimpl String.Chars, for: DataTree.TreePath do
    def to_string(path) do
      path.segments |> Enum.reverse |> Enum.join(DataTree.TreePath.separator)
    end
  end
end
