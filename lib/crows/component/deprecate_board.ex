defmodule Crows.Component.DeprecateBoard do
  @moduledoc false
  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitives

  # TODO: Defaults can go in an internal struct that can be later merged with an options parameter.
  # TODO: A single capture input for the whole board component.
  @default_size 67
  @default_color_a :light_steel_blue
  @default_color_b :antique_white
  # @default_highlight {0, 0xFF, 0xFF, 0x33}
  @default_highlight {0, 0xFF, 0xFF, 127}
  @grid_size_x 8
  @grid_size_y 8
  @width @default_size * @grid_size_x
  @height @default_size * @grid_size_y

  @impl Scenic.Component
  def validate([]), do: {:ok, []}
  def validate(_), do: :invalid_data

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    # :ok = Scene.capture_input(scene, [:cursor_button, :cursor_pos])

    board =
      Graph.build()
      # |> Primitives.rectangle({@width, @height},
      #  fill: {0, 0, 0, 0},
      #  id: :board,
      #  input: [:cursor_button, :cursor_pos]
      # )
      |> grid(&checkered_square/2)
      |> grid(&highlight_square/2)
      |> grid(&sprite_square/2)
      |> input_square()

    _timer_ref = Process.send_after(self(), :update_sprite, 500)

    {:ok,
     scene
     |> Scene.assign(:graph, board)
     |> push_graph(board)}
  end

  defp grid(graph, fun) do
    for y <- 1..@grid_size_y,
        x <- 1..@grid_size_y,
        reduce: graph,
        do: (graph -> fun.(graph, {x, y}))
  end

  defp checkered_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      stroke: {1, :slate_gray},
      translate: position(coordinate),
      fill: switch_color(coordinate)
    )
  end

  defp highlight_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      stroke: {2, {0, 0, 0, 0}},
      translate: position(coordinate),
      fill: {0, 0, 0, 0},
      hidden: false,
      id: {:highlight, coordinate}
    )
  end

  defp sprite_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      stroke: {0, {0, 0, 0, 0}},
      translate: position(coordinate),
      fill: {0, 0, 0, 0},
      hidden: false,
      id: {:sprite, coordinate}
    )
  end

  defp input_square(graph) do
    Primitives.rectangle(graph, {@width, @height},
      fill: {0, 0, 0, 0},
      stroke: {3, {255, 255, 255, 255}},
      hidden: false,
      id: :input_square,
      input: [:cursor_button, :cursor_pos]
    )
  end

  defp stroke(graph, id, stroke) do
    Graph.modify(graph, id, fn primitive ->
      Primitive.put_style(primitive, :stroke, stroke)
    end)
  end

  defp fill(graph, id, filling) do
    Graph.modify(graph, id, fn primitive ->
      Primitive.put_style(primitive, :fill, filling)
    end)
  end

  defp cap_input(graph, id, input) do
    Graph.modify(graph, id, fn primitive ->
      Primitives.update_opts(primitive, input: input)
    end)
  end

  defp rel_input(graph, id) do
    Graph.modify(graph, id, fn primitive ->
      Primitives.update_opts(primitive, input: [])
    end)
  end

  defp switch_color(coordinates) do
    case coordinates do
      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 0 ->
        @default_color_a

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 0 ->
        @default_color_b

      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 1 ->
        @default_color_b

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 1 ->
        @default_color_a
    end
  end

  defp position({x, y}) do
    # Inverts the positions in which the board is drawn
    # bottom up instead of up to bottom
    position_x = (x - 1) * @default_size
    position_y = (y - 1 - 7) * -1 * @default_size

    {position_x, position_y}
  end

  @impl Scenic.Components
  def bounds(_, _) do
    # left top right bottom
    {100, 100, 400, 400}
  end

  @impl Scenic.Scene
  def handle_input(event = {:cursor_button, {_button, _value, _mods, _position}}, _id, scene) do
    # :ok = Scene.send_parent_event(scene, {:test_event, :test})

    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_input(event = {:cursor_pos, _position}, id = {:highlight, {x, y}}, scene) do
    graph = Scene.get(scene, :graph)

    coordinates =
      for y <- 1..@grid_size_y,
          x <- 1..@grid_size_y,
          do: {x, y}

    ids = around({x, y})

    # Release input
    graph =
      Enum.reduce(coordinates, graph, fn id, graph ->
        graph
        # |> rel_input({:highlight, id})
        |> fill({:highlight, id}, {0, 0, 0, 0})
      end)

    # Capture input
    graph =
      Enum.reduce(ids, graph, fn id, graph ->
        # graph
        # |> cap_input({:highlight, id}, [:cursor_pos, :cursor_button])
        # |> fill({:highlight, id}, @default_highlight)
        # |> stroke({:highlight, id}, {5, {0xff, 0xff, 0xff, 1}})
        Graph.modify(graph, {:highlight, id}, fn primitive ->
          Primitives.update_opts(primitive,
            fill: @default_highlight,
            stroke: {5, {0xFF, 0xFF, 0xFF, 1}}
          )
        end)
      end)

    # :ok = Scene.send_parent_event(scene, {:test_event, :test})

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> push_graph(graph)}
  end

  def handle_input({:cursor_pos, position}, :input_square, scene) do
    graph = Scene.get(scene, :graph)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> push_graph(graph)}
  end

  def handle_input(event, _id, scene) do
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info(:update_sprite, scene) do
    state = Scene.get(scene, :sprite_state)

    position =
      if state,
        do:
          {{0, 0}, {32, 32}, {@default_size, @default_size + 5}, {@default_size, @default_size}},
        else: {{0, 0}, {32, 32}, {@default_size, @default_size}, {@default_size, @default_size}}

    graph =
      Scene.get(scene, :graph)
      |> Graph.modify(:generic_sprite, fn sprite ->
        Primitives.sprites(sprite, {:generic, [position]})
      end)

    _timer_ref = Process.send_after(self(), :update_sprite, 500)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:sprite_state, not state)
     |> push_graph(graph)}
  end

  defp around({x, y}) do
    around =
      for dx <- [-1, 0, 1],
          dy <- [-1, 0, 1],
          do: {x + dx, y + dy}

    Enum.filter(around, fn
      {^x, ^y} -> false
      {x, y} when x in 1..@grid_size_x and y in 1..@grid_size_y -> true
      {_x, _y} -> false
    end)
  end

  @spec calculate_position(Scenic.Math.point()) :: {non_neg_integer(), non_neg_integer()}
  defp calculate_position({x, y}) do
    # Transform to integer
    {x, _} = x |> Float.to_string() |> Integer.parse()
    {y, _} = y |> Float.to_string() |> Integer.parse()

    # From pointer coordinate to board position
    x = div(x, @default_size) + 1
    y = div(y, @default_size) + 1

    # Inverts position to present in bottom up
    y = (y - 8) * -1 + 1
    # position_x = (x - 1) * @default_size
    # position_y = (y - 1 - 8) * -1 * @default_size

    {x, y}
  end

  # @default_size 67
  # @grid_size_x 8
  # @grid_size_y 8
  # @grid_size {@grid_size_x, @grid_size_y}
  # @width @default_size * @grid_size_x
  # @height @default_size * @grid_size_y
  # end
end
