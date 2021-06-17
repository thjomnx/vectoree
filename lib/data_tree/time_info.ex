defmodule DataTree.TimeInfo do
  defstruct created: 0, modified: 0, extra: %{}

  @inherited :inherited

  def new() do
    now = DateTime.utc_now()
    %__MODULE__{created: now, modified: now}
  end

  def inherit() do
    @inherited
  end

  def is_inherited(@inherited), do: true
  def is_inherited(%__MODULE__{}), do: false
end
