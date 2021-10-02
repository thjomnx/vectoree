defmodule DataTree.TreePath do
  @type t :: %__MODULE__{}

  @separator "."
  @separator_replacement "_" <> Base.encode16(@separator, case: :lower)

  defstruct segments: []

  @doc ~S"""
  Creates a new struct from a singular `segment` or a list of `segments`.

  An empty singular `segment` results in a struct with zero segments.
  Lists of `segments` are filtered for empty elements. An empty list,
  also as a consequence after filtering, results in a struct with zero
  segments. Whitespace on each `segment` is preserved.

  ## Examples

  By passing a singular segment:

      iex> DataTree.TreePath.new("data")
      %DataTree.TreePath{segments: ["data"]}

      iex> DataTree.TreePath.new("  da ta  ")
      %DataTree.TreePath{segments: ["  da ta  "]}

      iex> DataTree.TreePath.new("  ")
      %DataTree.TreePath{segments: ["  "]}

      iex> DataTree.TreePath.new("")
      %DataTree.TreePath{segments: []}

  By passing a list of segments:

      iex> DataTree.TreePath.new([])
      %DataTree.TreePath{segments: []}

      iex> DataTree.TreePath.new(["data"])
      %DataTree.TreePath{segments: ["data"]}

      iex> DataTree.TreePath.new(["  data  ", "lo  re", "b4"])
      %DataTree.TreePath{segments: ["b4", "lo  re", "  data  "]}
  """
  @spec new(segment) :: t when segment: String.t()
  def new(segment) when is_binary(segment) do
    case segment do
      "" -> %__MODULE__{segments: []}
      _ -> %__MODULE__{segments: [segment]}
    end
  end

  @spec new(segments) :: t when segments: list()
  def new(segments) when is_list(segments) do
    filtered_segments =
      segments
      |> Enum.filter(&(String.length(&1) > 0))
      |> Enum.reverse()

    %__MODULE__{segments: filtered_segments}
  end

  @doc ~S"""
  Creates a new struct by wrapping the provided list of `segments`.

  The given list is taken as-is, i.e. without any filtering and by
  expecting it to be already in reversed order.

  ## Examples

  Here wrapping a path named "data.lore.b4":

      iex> DataTree.TreePath.wrap(["b4", "lore", "data"])
      %DataTree.TreePath{segments: ["b4", "lore", "data"]}
  """
  @spec wrap(segments) :: t when segments: list()
  def wrap(segments) when is_list(segments) do
    %__MODULE__{segments: segments}
  end

  @doc ~S"""
  Handles the sigil `~p` for tree paths.

  ## Examples

      iex> ~p""
      %DataTree.TreePath{segments: []}

      iex> ~p"data.lore.b4"
      %DataTree.TreePath{segments: ["b4", "lore", "data"]}

      iex> x = "or"
      iex> ~p"da#{:t}a.l#{x}e.b4"
      %DataTree.TreePath{segments: ["b4", "lore", "data"]}
  """
  defmacro sigil_p({:<<>>, _line, [term]}, []) when is_binary(term) do
    reversed = transpose_segments(term)

    quote do
      DataTree.TreePath.wrap(unquote(reversed))
    end
  end

  defmacro sigil_p({:<<>>, _line, terms}, []) when is_list(terms) do
    reversed = transpose_segments(terms)

    quote do
      DataTree.TreePath.wrap(unquote(reversed))
    end
  end

  @doc false
  def transpose_segments(term) when is_binary(term) do
    term
    |> String.split(@separator)
    |> Stream.filter(&(&1 != ""))
    |> Enum.reverse()
  end

  def transpose_segments(terms) when is_list(terms) do
    escape = fn
      {:"::", _, [expr, _]} -> expr
      binary when is_binary(binary) -> Macro.unescape_string(binary)
    end

    reduce = fn term, acc ->
      acc_head = List.first(acc)

      cond do
        is_binary(term) ->
          segments = String.split(term, @separator)

          if is_tuple(acc_head) do
            [segm_head | segm_tail] = segments
            acc = List.update_at(acc, 0, fn i -> quote do: unquote(i) <> unquote(segm_head) end)
            Enum.reverse(segm_tail) ++ acc
          else
            Enum.reverse(segments) ++ acc
          end

        is_tuple(term) ->
          if acc_head do
            List.update_at(acc, 0, fn i -> quote do: unquote(i) <> unquote(term) end)
          else
            [term | acc]
          end

        true ->
          acc
      end
    end

    terms
    |> Stream.map(&escape.(&1))
    |> Enum.reduce([], reduce)
    |> Enum.filter(&(&1 != ""))
  end

  @doc ~S"""
  Returns the path separator character as a `BitString`.
  """
  @spec separator() :: String.t()
  def separator(), do: @separator

  @doc ~S"""
  Returns the path separator character replacement as a `BitString`.

  The replacement is built using the underscore character `_` followed by
  the Base64 encoded form of the separator character.
  """
  @spec separator_replacement() :: String.t()
  def separator_replacement(), do: @separator_replacement

  @doc ~S"""
  Returns the level of the path.

  The level corresponds to the number of path segments.
  """
  @spec level(t) :: integer()
  def level(%__MODULE__{segments: segments}) do
    length(segments)
  end

  @doc ~S"""
  Returns a new struct which wraps the root segment of the given path.

  ## Examples

      iex> DataTree.TreePath.root(~p"")
      %DataTree.TreePath{segments: []}

      iex> DataTree.TreePath.root(~p"data")
      %DataTree.TreePath{segments: ["data"]}

      iex> DataTree.TreePath.root(~p"data.lore.b4")
      %DataTree.TreePath{segments: ["data"]}
  """
  @spec root(t) :: t
  def root(%__MODULE__{} = path) do
    path |> rootname |> new
  end

  @doc ~S"""
  Returns the root segment name of the given path as a `BitString`.

  ## Examples

      iex> DataTree.TreePath.rootname(~p"")
      ""

      iex> DataTree.TreePath.rootname(~p"data")
      "data"

      iex> DataTree.TreePath.rootname(~p"data.lore.b4")
      "data"
  """
  @spec rootname(t) :: String.t()
  def rootname(%__MODULE__{segments: segments}) do
    case List.last(segments) do
      nil -> ""
      x -> x
    end
  end

  @doc ~S"""
  Returns a new struct which wraps the parent segment of the given path.

  ## Examples

      iex> DataTree.TreePath.parent(~p"")
      %DataTree.TreePath{segments: []}

      iex> DataTree.TreePath.parent(~p"data")
      %DataTree.TreePath{segments: []}

      iex> DataTree.TreePath.parent(~p"data.lore.b4")
      %DataTree.TreePath{segments: ["lore", "data"]}
  """
  @spec parent(t) :: t
  def parent(%__MODULE__{segments: segments} = path) do
    case segments do
      [_ | tail] -> tail |> wrap
      _ -> path
    end
  end

  @doc ~S"""
  Returns a new structs which wraps the base segment of the given path.

  ## Examples

      iex> DataTree.TreePath.base(~p"")
      %DataTree.TreePath{segments: []}

      iex> DataTree.TreePath.base(~p"data")
      %DataTree.TreePath{segments: ["data"]}

      iex> DataTree.TreePath.base(~p"data.lore.b4")
      %DataTree.TreePath{segments: ["b4"]}
  """
  def base(%__MODULE__{segments: segments} = path) do
    case segments do
      [head | _] -> head |> new
      _ -> path
    end
  end

  @doc ~S"""
  Returns the base segment name of the given path as a `BitString`.

  ## Examples

      iex> DataTree.TreePath.basename(~p"")
      ""

      iex> DataTree.TreePath.basename(~p"data")
      "data"

      iex> DataTree.TreePath.basename(~p"data.lore.b4")
      "b4"
  """
  def basename(%__MODULE__{segments: segments}) do
    case segments do
      [head | _] -> head
      _ -> ""
    end
  end

  @doc ~S"""
  TODO
  """
  def sibling(%__MODULE__{} = path, segment) when is_binary(segment) do
    case segment do
      "" -> path
      _ -> [segment | parent(path).segments] |> wrap
    end
  end

  @doc ~S"""
  TODO
  """
  def append(%__MODULE__{segments: segments} = path, segment) when is_binary(segment) do
    case segment do
      "" -> path
      _ -> [segment | segments] |> wrap
    end
  end

  def append(%__MODULE__{segments: segments}, %__MODULE__{segments: more}) do
    (more ++ segments) |> wrap
  end

  @doc ~S"""
  TODO
  """
  def starts_with?(%__MODULE__{segments: segments}, prefix) do
    fun = &(segments |> Enum.reverse() |> List.starts_with?(&1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_list(prefix) -> fun.(prefix)
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse())
    end
  end

  @doc ~S"""
  TODO
  """
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
