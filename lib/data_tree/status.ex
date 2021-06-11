defmodule DataTree.Status do
  defstruct valid: true, extra: %{}

  @inherited :inherited

  def new() do
    %__MODULE__{}
  end

  def inherit() do
    @inherited
  end

  def is_inherited(@inherited), do: true
  def is_inherited(%__MODULE__{}), do: false
end
