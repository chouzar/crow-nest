defmodule CrowNest.Component.Board do
  @moduledoc false
  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitives
  alias Scenic.Primitive

  # TODO: Defaults can go in an internal struct that can be later merged with an options parameter.
  # TODO: A single capture input for the whole board component.

  # Size defaults
  @default_size 67
  @grid_size_x 8
  @grid_size_y 8
  @width @default_size * @grid_size_x
  @height @default_size * @grid_size_y
  @sprite_size 16

  # Color defaults
  @check_board_color_a :light_steel_blue
  @check_board_color_b :antique_white
  @highlight_board_color_path {0, 0xFF, 0xFF, 127}

  # Input defaults
  @btn_press 1
  @btn_release 0

  # These datastructures are used internally to draw the board
  @type position :: {non_neg_integer(), non_neg_integer()}
  @type piece :: :pawn | :rook | :knight | :bishop | :queen | :king
  @type piece_color :: :p1 | :p2
  @type path :: list(position)
  @type space :: {position(), piece(), piece_color(), path()}
  @type board :: %{position() => space()}

  @impl Scenic.Component
  def validate(%{}), do: {:ok, %{}}

  def validate(_) do
    {:error,
     """
     Must work on what params to pass
     """}
  end

  @impl Scenic.Scene
  def init(scene, spaces, opts) do
    :ok = Scene.capture_input(scene, [:cursor_button, :cursor_pos])

    graph =
      Graph.build()
      |> grid(&checkered_square/2)
      |> grid(&highlight_square/2)
      |> grid(&sprite_square/2)
      |> Primitives.sprites(
        {:spritesheet_piece_black,
         [
           draw_piece(:pawn, {1, 1}),
           draw_piece(:rook, {2, 1}),
           draw_piece(:knight, {3, 1}),
           draw_piece(:bishop, {4, 1}),
           draw_piece(:bishop, {7, 2}),
           draw_piece(:bishop, {8, 3}),
           draw_piece(:queen, {5, 1}),
           draw_piece(:king, {6, 1})
         ]},
        id: :spritesheet_black
      )
      |> Primitives.sprites(
        {:spritesheet_piece_white,
         [
           draw_piece(:pawn, {1, 8}),
           draw_piece(:rook, {2, 8}),
           draw_piece(:knight, {3, 8}),
           draw_piece(:bishop, {4, 8}),
           draw_piece(:bishop, {7, 8}),
           draw_piece(:bishop, {8, 8}),
           draw_piece(:queen, {5, 8}),
           draw_piece(:king, {6, 8})
         ]},
        id: :spritesheet_white
      )

    {:ok,
     scene
     |> Scene.assign(:id, opts[:id])
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:spaces, spaces)
     |> Scene.assign(:hover, :out_of_bounds)
     |> Scene.assign(:click, :none)
     |> push_graph(graph)}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_pos, position}, _id, scene) do
    graph = Scene.get(scene, :graph)

    current_position = Scene.get(scene, :hover)

    case to_position(position) do
      ^current_position ->
        # Remains same coordinate, do nothing
        {:noreply, scene}

      new_position ->
        # Changed board coordinate, send to parent scene
        :ok = send_parent(scene, :hover, new_position)

        {:noreply,
         scene
         |> Scene.assign(:graph, graph)
         |> Scene.assign(:hover, new_position)
         |> push_graph(graph)}
    end
  end

  def handle_input({:cursor_button, {:btn_left, @btn_press, _mods, position}}, _id, scene) do
    to_position = to_position(position)
    :ok = send_parent(scene, :left_click, to_position)

    {:noreply, scene}
  end

  def handle_input({:cursor_button, {:btn_right, @btn_press, _mods, position}}, _id, scene) do
    to_position = to_position(position)
    :ok = send_parent(scene, :right_click, to_position)

    graph =
      Scene.get(scene, :graph)
      |> Graph.modify({:highlight, to_position}, fn primitive ->
        Primitives.update_opts(primitive,
          fill: @highlight_board_color_path,
          stroke: {5, {0xFF, 0xFF, 0xFF, 1}}
        )
      end)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:click, to_position)
     |> push_graph(graph)}
  end

  def handle_input({:cursor_button, {:btn_right, @btn_release, _mods, position}}, _id, scene) do
    click_position = Scene.get(scene, :click)
    to_position = to_position(position)
    :ok = send_parent(scene, :right_click_release, to_position)

    graph =
      Scene.get(scene, :graph)
      |> Graph.modify({:highlight, click_position}, fn primitive ->
        Primitives.update_opts(primitive,
          fill: {0, 0, 0, 0},
          stroke: {5, {0, 0, 0, 0}}
        )
      end)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:click, to_position)
     |> push_graph(graph)}
  end

  def handle_input({:cursor_button, {_button, _value, _mods, _position}}, _id, scene) do
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_fetch(from, scene) do
    spaces = Scene.get(scene, :spaces)

    {:reply, {:ok, spaces}, scene}
  end

  @impl Scenic.Scene
  def handle_get(from, scene) do
    spaces = Scene.get(scene, :spaces)

    {:reply, spaces, scene}
  end

  @impl Scenic.Scene
  def handle_put(value, scene) do
    {:noreply, scene}
  end

  defp send_parent(scene, event, data) do
    id = Scene.get(scene, :id)
    Scene.send_parent_event(scene, {event, id, data})
  end

  # Initialize board logic

  defp grid(graph, fun) do
    for y <- 1..@grid_size_y,
        x <- 1..@grid_size_y,
        reduce: graph,
        do: (graph -> fun.(graph, {x, y}))
  end

  defp checkered_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      translate: to_point(coordinate),
      fill: switch_color(coordinate),
      stroke: {1, :slate_gray}
    )
  end

  defp highlight_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      translate: to_point(coordinate),
      fill: {0, 0, 0, 0},
      stroke: {2, {0, 0, 0, 0}},
      hidden: false,
      id: {:highlight, coordinate}
    )
  end

  defp sprite_square(graph, {_x, _y} = coordinate) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      translate: to_point(coordinate),
      fill: {0, 0, 0, 0},
      stroke: {0, {0, 0, 0, 0}},
      hidden: false,
      id: {:sprite, coordinate}
    )
  end

  # TODO: This could be provided as a lambda option to pass around
  defp switch_color(coordinates) do
    case coordinates do
      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 0 ->
        @check_board_color_a

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 0 ->
        @check_board_color_b

      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 1 ->
        @check_board_color_b

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 1 ->
        @check_board_color_a
    end
  end

  @spec to_position(Scenic.Math.point()) ::
          position()
          | :out_of_bounds
  defp to_position({x, y}) do
    case {x, y} do
      {x, y}
      when x >= 0 and x <= @width and
             y >= 0 and y <= @height ->
        # Transform to integer
        {x, _} = x |> Float.to_string() |> Integer.parse()
        {y, _} = y |> Float.to_string() |> Integer.parse()

        # From pointer coordinate to board position
        x = div(x, @default_size)
        y = div(y, @default_size)

        # Invert y axis
        x = x + 1
        y = (y - 8) * -1

        {x, y}

      {_x, _y} ->
        :out_of_bounds
    end
  end

  @spec to_point(position()) :: Scenic.Math.point()
  defp to_point({x, y}) do
    x = x - 1
    y = (y - 8) * -1
    {x * @default_size, y * @default_size}
  end

  # @spec set_pieces(Scene.t(), list(piece)) :: Scene.t()
  # defp set_pieces(scene, pieces) do
  #  Graph.modify(graph, :spritesheet_black, fn sheet ->
  #    Primitives.sprites(sheet, pieces)
  #  end)
  # end

  # defp set_black_pieces(graph, spritesheet_id, pieces) do
  #  Graph.modify(graph, :spritesheet_black, fn sheet ->
  #    Primitives.sprites(sheet, pieces)
  #  end)
  # end

  # defp set_white_pieces(graph, spritesheet_id, pieces) do
  #  Graph.modify(graph, :spritesheet_white, fn sheet ->
  #    Primitives.sprites(sheet, pieces)
  #  end)
  # end
  #
  # defp set_highlight() do
  #
  # end

  @spec draw_piece(piece(), position()) :: Scenic.Primitive.Sprites.draw_cmd()
  defp draw_piece(piece, {x, y}) do
    case piece do
      :pawn -> draw_command({00, 00}, {x, y})
      :rook -> draw_command({16, 00}, {x, y})
      :knight -> draw_command({00, 16}, {x, y})
      :bishop -> draw_command({16, 16}, {x, y})
      :queen -> draw_command({00, 32}, {x, y})
      :king -> draw_command({16, 32}, {x, y})
    end
  end

  @spec draw_command(position(), position()) :: Scenic.Primitive.Sprites.draw_cmd()
  defp draw_command({sprite_x, sprite_y}, {x, y}) do
    {point_x, point_y} = to_point({x, y})

    {{sprite_x, sprite_y}, {@sprite_size, @sprite_size}, {point_x, point_y},
     {@default_size, @default_size}}
  end
end
