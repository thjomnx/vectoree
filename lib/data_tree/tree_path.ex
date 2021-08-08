defmodule DataTree.TreePath do
  @separator "."
  @separator_replacement "_" <> Base.encode16(@separator, case: :lower)

  defstruct segments: []

  def new(segment) when is_binary(segment), do: [segment] |> init
  def new(segments) when is_list(segments), do: segments |> init_reversed

  defmacro sigil_p({:<<>>, _, [term]}, []) when is_binary(term) do
    reversed =
      term
      |> String.split(@separator)
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))
      |> Enum.reverse()

    quote do
      DataTree.TreePath.wrap(unquote(reversed))
    end
  end

  defmacro sigil_p({:<<>>, _line, terms}, []) do
    escape = fn
      {:"::", _, [expr, _]} ->
        expr

      binary when is_binary(binary) ->
        :elixir_interpolation.unescape_string(binary) |> String.trim(@separator)
    end

    reversed =
      terms
      |> Enum.filter(&(&1 != @separator))
      |> Enum.map(&escape.(&1))
      |> Enum.reverse()

    quote do
      DataTree.TreePath.wrap(unquote(reversed))
    end
  end

  def wrap(segments) when is_list(segments) do
    %__MODULE__{segments: segments}
  end

  defp init(segments) when is_list(segments) do
    %__MODULE__{segments: segments |> normalize}
  end

  defp init_reversed(segments) do
    %__MODULE__{segments: segments |> normalize |> Enum.reverse()}
  end

  defp init_single(segment) when is_binary(segment) do
    case segment do
      "" -> %__MODULE__{segments: []}
      _ -> %__MODULE__{segments: [segment]}
    end
  end

  def normalize(segments) when is_list(segments) do
    Enum.filter(segments, &(String.length(&1) > 0))
  end

  def separator(), do: @separator
  def separator_replacement(), do: @separator_replacement

  def level(%__MODULE__{segments: segments}) do
    length(segments)
  end

  def root(%__MODULE__{} = path) do
    path |> rootname |> init_single
  end

  def rootname(%__MODULE__{segments: segments}) do
    case List.last(segments) do
      nil -> ""
      x -> x
    end
  end

  def parent(%__MODULE__{segments: segments} = path) do
    case segments do
      [_ | tail] -> tail |> wrap
      _ -> path
    end
  end

  def base(%__MODULE__{segments: segments} = path) do
    case segments do
      [head | _] -> head |> init_single
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
    case segment do
      "" -> path
      _ -> [segment | parent(path).segments] |> wrap
    end
  end

  def append(%__MODULE__{segments: segments} = path, segment) when is_binary(segment) do
    case segment do
      "" -> path
      _ -> [segment | segments] |> wrap
    end
  end

  def append(%__MODULE__{segments: segments}, %__MODULE__{segments: more}) do
    (more ++ segments) |> wrap
  end

  def starts_with?(%__MODULE__{segments: segments}, prefix) do
    fun = &(segments |> Enum.reverse() |> List.starts_with?(&1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_list(prefix) -> fun.(prefix)
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse())
    end
  end

  def ends_with?(%__MODULE__{segments: segments}, suffix) do
    fun = &List.starts_with?(segments, &1)

    cond do
      is_binary(suffix) -> fun.([suffix])
      is_list(suffix) -> fun.(suffix)
      is_struct(suffix, __MODULE__) -> fun.(suffix.segments)
    end
  end

  defimpl String.Chars, for: DataTree.TreePath do
    def to_string(path) do
      sep = DataTree.TreePath.separator()
      repl = DataTree.TreePath.separator_replacement()

      path.segments
      |> Enum.reverse()
      |> Enum.map(&String.replace(&1, sep, repl))
      |> Enum.join(DataTree.TreePath.separator())
    end
  end
end
