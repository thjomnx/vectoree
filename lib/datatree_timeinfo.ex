defmodule DataTree.TimeInfo do
  defstruct created: 0, modified: 0, extra: %{}

  def new() do
    now = DateTime.utc_now()
    %DataTree.TimeInfo{created: now, modified: now}
  end
end
