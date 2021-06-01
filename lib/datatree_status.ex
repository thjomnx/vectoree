defmodule DataTree.Status do
  defstruct valid: true, extra: %{}

  def new() do
    %DataTree.Status{}
  end
end
