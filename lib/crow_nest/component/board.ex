defmodule CrowNest.Component.Board do
  @moduledoc false
  use Scenic.Component, has_children: false

  require Logger

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitives

  # TODO: Defaults can go in an internal struct that can be later merged with an options parameter.

  # Size defaults
  @default_size 67
  @grid_size_x 8
  @grid_size_y 8
  @width @default_size * @grid_size_x
  @height @default_size * @grid_size_y
  @sprite_size 16

  # These datastructures are used internally to draw the board
  @type position :: {non_neg_integer(), non_neg_integer()}
  @type piece :: :pawn | :rook | :knight | :bishop | :queen | :king
  @type piece_color :: :p1 | :p2
  @type path :: list(position)
  @type space :: {position(), piece(), piece_color(), path()}
  @type board :: %{position() => space()}

  @all_positions for y <- 1..@grid_size_y, x <- 1..@grid_size_y, do: {x, y}

  ## Blue / Pink
  @c_transparent {0x00, 0x00, 0x00, 000}
  @c_highlight {0x62, 0x35, 0x6E, 085}
  @c_move {0x62, 0x35, 0x6E, 170}
  @c_capture {0xf9, 0x00, 0x01, 255}

  # Green / Paper checkered board
  @c_checkered_a {0x45, 0x6D, 0x69, 0xFF}
  @c_checkered_b {0xF1, 0xF3, 0xE5, 0xFF}

  @impl Scenic.Component
  def validate(data) do
    # {:error, "this will raise an error"}
    {:ok, data}
  end

  @impl Scenic.Scene
  def init(scene, {player_positions_a, player_positions_b}, opts) do
    :ok = Scene.capture_input(scene, [:cursor_button, :cursor_pos])

    graph =
      Graph.build()
      |> new_checkered_board()
      |> new_highlight_board()
      |> new_piece_spritesheet(player_positions_a, :spritesheet_piece_black)
      |> new_piece_spritesheet(player_positions_b, :spritesheet_piece_white)

    {:ok,
     scene
     |> Scene.assign(:id, opts[:id])
     |> Scene.assign(:graph, graph)
     # The board value is a map datastructure
     |> Scene.assign(:player_positions, {player_positions_a, player_positions_b})
     # On startup we can only inspect pieces paths
     |> Scene.assign(:mode, :cursor)
     # The pointer is either in a coordinate or out of bounds
     |> Scene.assign(:hover, :out_of_bounds)
     # Annotates the position of our last click
     |> Scene.assign(:click, :none)
     # Annotates the path/captures of our last selected piece
     |> Scene.assign(:path, [])
     |> Scene.assign(:captures, [])
     |> push_graph(graph)}
  end

  @impl Scenic.Scene
  def handle_input({:cursor_pos, position}, _id, scene) do
    mode = Scene.get(scene, :mode)
    current_position = Scene.get(scene, :hover)
    new_position = to_position(position)

    case {mode, current_position, new_position} do
      {_mode, current, current} ->
        # Remains same coordinate, do nothing
        {:noreply, scene}

      {:cursor, _current, new} ->
        {:noreply,
         scene
         |> highlight_path(new)
         |> Scene.assign(:hover, new)
         |> render()}

      {:move, _current, new} ->
        {:noreply,
         scene
         |> Scene.assign(:hover, new)
         |> render()}
    end
  end

  @btn_press 1
  # @btn_release 0

  def handle_input({:cursor_button, {:btn_left, @btn_press, _mods, position}}, _id, scene) do
    path = Scene.get(scene, :path)
    from_position = Scene.get(scene, :click)
    to_position = to_position(position)

    # If click is ona unit that can move...
    #
    {player_positions_a, player_positions_b} = Scene.get(scene, :player_positions)
    positions = Map.merge(player_positions_a, player_positions_b)

    case {Scene.get(scene, :mode), Map.get(positions, to_position)} do
      {:cursor, nil} ->
        {:noreply, scene}

      {:cursor, %{can_move: true}} ->
        {:noreply,
         scene
         |> move_path(to_position)
         |> Scene.assign(:mode, :move)
         |> Scene.assign(:click, to_position)
         |> render()}

      {:cursor, %{can_move: false}} ->
        {:noreply,
         scene
         |> Scene.assign(:click, to_position)
         |> render()}

      {:move, _check} ->
        if MapSet.member?(MapSet.new(path), to_position) do
          # If click goes inside highlighted path
          :ok = send_parent(scene, :move, {from_position, to_position})
        end

        {:noreply,
         scene
         |> clear_path()
         |> Scene.assign(:mode, :cursor)
         |> Scene.assign(:click, to_position)
         |> render()}
    end
  end

  def handle_input({:cursor_button, {_button, _value, _mods, _position}}, _id, scene) do
    {:noreply, scene}
  end

  @impl Scenic.Scene
  def handle_put({player_positions_a, player_positions_b}, scene) do
    graph =
      Scene.get(scene, :graph)
      |> update_piece_spritesheet(player_positions_a, :spritesheet_piece_black)
      |> update_piece_spritesheet(player_positions_b, :spritesheet_piece_white)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:player_positions, {player_positions_a, player_positions_b})
     |> push_graph(graph)}
  end

  # Scene helpers

  defp clear_path(scene) do
    graph =
      Scene.get(scene, :graph)
      |> update_highlight_board(@all_positions, fill: @c_transparent, stroke: {0, @c_transparent})

    scene
    |> Scene.assign(:graph, graph)
    |> Scene.assign(:path, [])
    |> Scene.assign(:captures, [])
  end

  # TODO storing the current path and captures woudl maybe remove some conditional-repetitive logic
  defp move_path(scene, position) do
    {player_positions_a, player_positions_b} = Scene.get(scene, :player_positions)

    %{path: path, captures: captures} =
      player_positions_a
      |> Map.merge(player_positions_b)
      |> Map.get(position, %{path: [], captures: []})

    graph =
      Scene.get(scene, :graph)
      |> update_highlight_board(@all_positions, fill: @c_transparent, stroke: {0, @c_transparent})
      |> update_highlight_board(path, fill: @c_move, stroke: {0, @c_move})

    scene
    |> Scene.assign(:graph, graph)
    |> Scene.assign(:path, path)
    |> Scene.assign(:captures, captures)
  end

  # TODO storing the current path and captures woudl maybe remove some conditional-repetitive logic
  defp highlight_path(scene, position) do
    {player_positions_a, player_positions_b} = Scene.get(scene, :player_positions)

    %{path: path, captures: captures} =
      player_positions_a
      |> Map.merge(player_positions_b)
      |> Map.get(position, %{path: [], captures: []})

    graph =
      Scene.get(scene, :graph)
      |> update_highlight_board(@all_positions, fill: @c_transparent, stroke: {0, @c_transparent})
      |> update_highlight_board(path, fill: @c_highlight, stroke: {0, @c_highlight})
      |> update_highlight_board(captures, fill: @c_highlight, stroke: {2, @c_capture})

    scene
    |> Scene.assign(:graph, graph)
    |> Scene.assign(:path, path)
    |> Scene.assign(:captures, captures)
  end

  defp render(scene) do
    graph = Scene.get(scene, :graph)
    push_graph(scene, graph)
  end

  # Graph helpers

  defp new_checkered_board(graph) do
    Enum.reduce(@all_positions, graph, &new_checkered_square/2)
  end

  defp new_checkered_square({_x, _y} = coordinate, graph) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      translate: to_point(coordinate),
      fill: switch_color(coordinate),
      stroke: {1, :slate_gray}
    )
  end

  defp new_highlight_board(graph) do
    Enum.reduce(@all_positions, graph, &new_highlight_square/2)
  end

  defp new_highlight_square({_x, _y} = coordinate, graph) do
    Primitives.rectangle(graph, {@default_size, @default_size},
      translate: to_point(coordinate),
      fill: {0, 0, 0, 0},
      hidden: false,
      id: {:highlight, coordinate}
    )
  end

  defp new_piece_spritesheet(graph, positions, sheet) do
    draw_commands =
      Enum.map(positions, fn {position, check} ->
        draw_piece_command(position, check.piece)
      end)

    Primitives.sprites(graph, {sheet, draw_commands}, id: sheet)
  end

  defp update_piece_spritesheet(graph, positions, sheet_id) do
    draw_commands =
      Enum.map(positions, fn {position, check} ->
        draw_piece_command(position, check.piece)
      end)

    Graph.modify(graph, sheet_id, fn sheet ->
      Primitives.sprites(sheet, {sheet_id, draw_commands})
    end)
  end

  @spec draw_piece_command(piece(), position()) :: Scenic.Primitive.Sprites.draw_cmd()
  defp draw_piece_command({x, y}, piece) do
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

  defp update_highlight_board(graph, positions, opts) do
    Enum.reduce(positions, graph, &update_higlight_square(&1, &2, opts))
  end

  defp update_higlight_square({x, y} = _coordinate, graph, opts) do
    Graph.modify(graph, {:highlight, {x, y}}, fn primitive ->
      Primitives.update_opts(primitive, opts)
    end)
  end

  # Helpers

  defp send_parent(scene, event, data) do
    id = Scene.get(scene, :id)
    Scene.send_parent_event(scene, {event, id, data})
  end

  defp switch_color(coordinates) do
    case coordinates do
      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 0 ->
        @c_checkered_a

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 0 ->
        @c_checkered_b

      {x, y} when rem(x, 2) == 0 and rem(y, 2) == 1 ->
        @c_checkered_b

      {x, y} when rem(x, 2) == 1 and rem(y, 2) == 1 ->
        @c_checkered_a
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
end
