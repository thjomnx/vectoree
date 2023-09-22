defmodule Vectoree.TreePath do
  @moduledoc """
  A canonical path implementation for tree structures.

  The functions in this module handle `TreePath` structs, which encapsulate path
  `segments` in a list in reverse order. There is no distinction between
  absolute and relative paths. Printable representations of such a struct use
  the dot `.` character as separator between segments.

  Developers should avoid creating the `TreePath` struct directly and instead
  rely on the functions provided by this module, including the provided sigil
  macros.
  """

  @separator "."
  @separator_replacement "_" <> Base.encode16(@separator, case: :lower)

  @type t :: %__MODULE__{
          segments: list(String.t())
        }

  defstruct segments: []

  @doc """
  Creates a new struct from a singular `segment` or a list of `segments`.

  An empty singular `segment` results in a struct with zero segments. Lists of
  `segments` are filtered for empty elements. An empty list, also as a
  consequence after filtering, results in a struct with zero segments.
  Whitespace on each `segment` is preserved.

  ## Examples

  By passing a singular segment:

      iex> Vectoree.TreePath.new("data")
      %Vectoree.TreePath{segments: ["data"]}

      iex> Vectoree.TreePath.new("  da ta  ")
      %Vectoree.TreePath{segments: ["  da ta  "]}

      iex> Vectoree.TreePath.new("  ")
      %Vectoree.TreePath{segments: ["  "]}

      iex> Vectoree.TreePath.new("")
      %Vectoree.TreePath{segments: []}

  By passing a list of segments:

      iex> Vectoree.TreePath.new([])
      %Vectoree.TreePath{segments: []}

      iex> Vectoree.TreePath.new(["data"])
      %Vectoree.TreePath{segments: ["data"]}

      iex> Vectoree.TreePath.new(["  data  ", "lo  re", "b4"])
      %Vectoree.TreePath{segments: ["b4", "lo  re", "  data  "]}
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

  @doc """
  Creates a new struct by wrapping the provided list of `segments`.

  The given list is taken as-is, i.e. without any filtering and by expecting it
  to be already in reversed order.

  ## Examples

  Here wrapping a path named "data.lore.b4":

      iex> Vectoree.TreePath.wrap(["b4", "lore", "data"])
      %Vectoree.TreePath{segments: ["b4", "lore", "data"]}
  """
  @spec wrap(segments) :: t when segments: list()
  def wrap(segments) when is_list(segments) do
    %__MODULE__{segments: segments}
  end

  @doc ~S"""
  Handles the sigil `~p` for tree paths.

  ## Examples

      iex> ~p""
      %Vectoree.TreePath{segments: []}

      iex> ~p"data.lore.b4"
      %Vectoree.TreePath{segments: ["b4", "lore", "data"]}

      iex> x = "or"
      iex> ~p"da#{:t}a.l#{x}e.b4"
      %Vectoree.TreePath{segments: ["b4", "lore", "data"]}
  """
  defmacro sigil_p({:<<>>, _line, [term]}, []) when is_binary(term) do
    reversed = transpose_segments(term)

    quote do
      Vectoree.TreePath.wrap(unquote(reversed))
    end
  end

  defmacro sigil_p({:<<>>, _line, terms}, []) when is_list(terms) do
    reversed = transpose_segments(terms)

    quote do
      Vectoree.TreePath.wrap(unquote(reversed))
    end
  end

  @doc false
  def transpose_segments(term) when is_binary(term) do
    term
    |> Macro.unescape_string()
    |> String.split(@separator)
    |> Stream.filter(&(&1 != ""))
    |> Enum.reverse()
  end

  def transpose_segments(terms) when is_list(terms) do
    extractor = fn
      {:"::", _, [expr, _]} -> expr
      binary when is_binary(binary) -> Macro.unescape_string(binary)
    end

    transposer = fn term, acc ->
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
    |> Stream.map(&extractor.(&1))
    |> Enum.reduce([], transposer)
    |> Enum.filter(&(&1 != ""))
  end

  @doc """
  Returns the path separator character as a `BitString`.
  """
  @spec separator() :: String.t()
  def separator(), do: @separator

  @doc """
  Returns the path separator character replacement as a `BitString`.

  The replacement is built using the underscore character `_` followed by the
  Base64 encoded form of the separator character.
  """
  @spec separator_replacement() :: String.t()
  def separator_replacement(), do: @separator_replacement

  @doc """
  Returns the level of the path.

  The level corresponds to the number of path segments.
  """
  @spec level(t) :: integer()
  def level(%__MODULE__{segments: segments}) do
    length(segments)
  end

  @doc """
  Returns a new struct which wraps the root segment of the given path.

  ## Examples

      iex> Vectoree.TreePath.root(~p"")
      %Vectoree.TreePath{segments: []}

      iex> Vectoree.TreePath.root(~p"data")
      %Vectoree.TreePath{segments: ["data"]}

      iex> Vectoree.TreePath.root(~p"data.lore.b4")
      %Vectoree.TreePath{segments: ["data"]}
  """
  @spec root(t) :: t
  def root(%__MODULE__{} = path) do
    path |> rootname |> new
  end

  @doc """
  Returns the root segment name of the given path as a `BitString`.

  ## Examples

      iex> Vectoree.TreePath.rootname(~p"")
      ""

      iex> Vectoree.TreePath.rootname(~p"data")
      "data"

      iex> Vectoree.TreePath.rootname(~p"data.lore.b4")
      "data"
  """
  @spec rootname(t) :: String.t()
  def rootname(%__MODULE__{segments: segments}) do
    case List.last(segments) do
      nil -> ""
      x -> x
    end
  end

  @doc """
  Returns a new struct which wraps the parent segment of the given path.

  ## Examples

      iex> Vectoree.TreePath.parent(~p"")
      %Vectoree.TreePath{segments: []}

      iex> Vectoree.TreePath.parent(~p"data")
      %Vectoree.TreePath{segments: []}

      iex> Vectoree.TreePath.parent(~p"data.lore.b4")
      %Vectoree.TreePath{segments: ["lore", "data"]}
  """
  @spec parent(t) :: t
  def parent(%__MODULE__{segments: segments} = path) do
    case segments do
      [_ | tail] -> tail |> wrap
      _ -> path
    end
  end

  @doc """
  Returns a new struct which wraps the base segment of the given path.

  ## Examples

      iex> Vectoree.TreePath.base(~p"")
      %Vectoree.TreePath{segments: []}

      iex> Vectoree.TreePath.base(~p"data")
      %Vectoree.TreePath{segments: ["data"]}

      iex> Vectoree.TreePath.base(~p"data.lore.b4")
      %Vectoree.TreePath{segments: ["b4"]}
  """
  @spec base(t) :: t
  def base(%__MODULE__{segments: segments} = path) do
    case segments do
      [head | _] -> head |> new
      _ -> path
    end
  end

  @doc """
  Returns the base segment name of the given path as a `BitString`.

  ## Examples

      iex> Vectoree.TreePath.basename(~p"")
      ""

      iex> Vectoree.TreePath.basename(~p"data")
      "data"

      iex> Vectoree.TreePath.basename(~p"data.lore.b4")
      "b4"
  """
  @spec basename(t) :: String.t()
  def basename(%__MODULE__{segments: segments}) do
    case segments do
      [head | _] -> head
      _ -> ""
    end
  end

  @doc """
  Returns a new struct which wraps a sibling of the given path.

  # Examples

      iex> Vectoree.TreePath.sibling(~p"data.lore", "b4")
      %Vectoree.TreePath{segments: ["b4", "data"]}

      iex> Vectoree.TreePath.sibling(~p"", "b4")
      %Vectoree.TreePath{segments: ["b4"]}
  """
  @spec sibling(t, String.t()) :: t
  def sibling(%__MODULE__{} = path, segment) when is_binary(segment) do
    case segment do
      "" -> path
      _ -> [segment | parent(path).segments] |> wrap
    end
  end

  @doc """
  Returns a new struct with the `segment` being appended on the given path.

  ## Examples

      iex> Vectoree.TreePath.append(~p"", "data")
      %Vectoree.TreePath{segments: ["data"]}

      iex> Vectoree.TreePath.append(~p"data.lore", "b4")
      %Vectoree.TreePath{segments: ["b4", "lore", "data"]}

      iex> Vectoree.TreePath.append(~p"data.lore", ~p"b4.soong")
      %Vectoree.TreePath{segments: ["soong", "b4", "lore", "data"]}
  """
  @spec append(t, String.t()) :: t
  def append(%__MODULE__{segments: segments} = path, segment) when is_binary(segment) do
    case segment do
      "" -> path
      _ -> [segment | segments] |> wrap
    end
  end

  @spec append(t, t) :: t
  def append(%__MODULE__{segments: segments}, %__MODULE__{segments: more}) do
    (more ++ segments) |> wrap
  end

  @doc """
  Checks if a path starts with the given `prefix`.

  ## Examples

      iex> Vectoree.TreePath.starts_with?(~p"data.lore.b4", "data")
      true

      iex> Vectoree.TreePath.starts_with?(~p"data.lore.b4", "lore")
      false

      iex> Vectoree.TreePath.starts_with?(~p"data.lore.b4", ~p"data.lore")
      true
  """
  @spec starts_with?(t, String.t() | t) :: boolean()
  def starts_with?(%__MODULE__{segments: segments}, prefix) do
    fun = &(segments |> Enum.reverse() |> List.starts_with?(&1))

    cond do
      is_binary(prefix) -> fun.([prefix])
      is_struct(prefix, __MODULE__) -> fun.(prefix.segments |> Enum.reverse())
    end
  end

  @doc """
  Checks if a path ends with the given `suffix`.

  ## Examples

      iex> Vectoree.TreePath.ends_with?(~p"data.lore.b4", "b4")
      true

      iex> Vectoree.TreePath.ends_with?(~p"data.lore.b4", "lore")
      false

      iex> Vectoree.TreePath.ends_with?(~p"data.lore.b4", ~p"lore.b4")
      true
  """
  @spec ends_with?(t, String.t() | t) :: boolean()
  def ends_with?(%__MODULE__{segments: segments}, suffix) do
    fun = &List.starts_with?(segments, &1)

    cond do
      is_binary(suffix) -> fun.([suffix])
      is_struct(suffix, __MODULE__) -> fun.(suffix.segments)
    end
  end

  defimpl String.Chars, for: Vectoree.TreePath do
    def to_string(path) do
      sep = Vectoree.TreePath.separator()
      repl = Vectoree.TreePath.separator_replacement()

      path.segments
      |> Enum.reverse()
      |> Enum.map(&String.replace(&1, sep, repl))
      |> Enum.join(Vectoree.TreePath.separator())
    end
  end
end
