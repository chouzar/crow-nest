defmodule Scen.MyComponent do
  @moduledoc false
  use Scenic.Component

  import Scenic.Primitives

  alias Scenic.Graph

  @impl Scenic.Component
  def validate(text) when is_binary(text), do: {:ok, text}
  def validate(_), do: :invalid_data

  # @impl Scenic.Component
  # def info(_error), do: "Must be initialized with a binary"

  @impl Scenic.Scene
  def init(scene, text, _opts) do
    # modify the already built graph
    graph =
      Graph.build()
      |> text(text, text_align: :center, translate: {100, 200}, id: :text)

    scene =
      scene
      |> assign(graph: graph, my_value: 123)
      |> push_graph(graph)

    {:ok, scene}
  end
end
