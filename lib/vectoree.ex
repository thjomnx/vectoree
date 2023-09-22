defmodule Vectoree do
  @moduledoc """
  Vectoree provides a bunch of modules for working with tree-ish data
  structures. The data structure is kept flat, i.e. all data is stored in plain
  maps. Each map entry consists of a key of type `TreePath` and an arbitrary
  payload. The `Tree` module provides functions for working with the tree (map).

  A `TreeServer` process acts as the central point, where the tree is assembled.
  Producers are "mounted", i.e. they contribute to the tree with their
  particular local tree (processes of types `TreeSource` and `TreeProcessor`).
  Consumers do listen on the tree and receive updates (processes of types
  `TreeProcessor` and `TreeSink`).

  Sources, processors and sinks are behaviour modules, which are supposed to be
  extended for custom use.

  The central server can be queried to return the aggregated subtree at a given
  path, i.e. it dispatches and receives the relevant local trees from all
  producers and reduces the data according to custom needs.
  """
end
