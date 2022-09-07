defmodule Scen.Home do
  use Scenic.Scene

  require Logger

  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    graph =
      board()
      |> Graph.modify({1, 1}, fn primitive -> rectangle(primitive, {100, 100}, scale: 1.5) end)
      |> text("Hello World", font_size: 22, translate: {200, 80})
      |> button("Do Something", translate: {200, 180})
      |> Scen.MyComponent.add_to_graph("setting up", translate: {20, 200})

    scene =
      scene
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_event({type, value}, _from, scene) do
    IO.inspect(type, label: :event_type)
    IO.inspect(value, label: :event_value)
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input(input, id, scene) do
    Logger.info(input)
    Logger.info(id)
    {:noreply, scene}
  end

  defp board() do
    {graph, _color} =
      for y <- 1..8, x <- 1..8, reduce: {Graph.build(), :antique_white} do
        {graph, color} ->
          IO.inspect(color)
          IO.inspect(x)
          IO.inspect(y)
          color = switch_color(color)

          graph =
            graph
            |> square({x, y}, color)
            |> text("{#{x},#{y}}", fill: :black, font_size: 12, translate: {x * 100 + 50, y * 100 + 50})

          {graph, color}
      end

    graph
  end

  defp switch_color(:light_steel_blue), do: :antique_white
  defp switch_color(:antique_white), do: :light_steel_blue

  defp square(graph, {x, y}, color) do
    rectangle(graph, {100, 100},
      stroke: {1, :slate_gray},
      translate: {x * 100, y * 100},
      fill: color,
      id: {x, y}
    )
  end
end
