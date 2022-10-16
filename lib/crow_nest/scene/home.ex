defmodule CrowNest.Scene.Home do
  use Scenic.Scene

  require Logger

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Primitives
  alias CrowNest.Translate

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    gamestate =
      :crow.new()
      |> :crow.players("charcoal", "bone")
      |> :crow.deploy("A7", "bone", :pawn)
      |> :crow.deploy("B7", "bone", :pawn)
      |> :crow.deploy("C7", "bone", :pawn)
      |> :crow.deploy("D7", "bone", :pawn)
      |> :crow.deploy("E7", "bone", :pawn)
      |> :crow.deploy("F7", "bone", :pawn)
      |> :crow.deploy("G7", "bone", :pawn)
      |> :crow.deploy("H7", "bone", :pawn)
      |> :crow.deploy("A8", "bone", :rook)
      |> :crow.deploy("B8", "bone", :knight)
      |> :crow.deploy("C8", "bone", :bishop)
      |> :crow.deploy("D8", "bone", :queen)
      |> :crow.deploy("E8", "bone", :king)
      |> :crow.deploy("F8", "bone", :bishop)
      |> :crow.deploy("G8", "bone", :knight)
      |> :crow.deploy("H8", "bone", :rook)
      |> :crow.deploy("A2", "charcoal", :pawn)
      |> :crow.deploy("B2", "charcoal", :pawn)
      |> :crow.deploy("C2", "charcoal", :pawn)
      |> :crow.deploy("D2", "charcoal", :pawn)
      |> :crow.deploy("E2", "charcoal", :pawn)
      |> :crow.deploy("F2", "charcoal", :pawn)
      |> :crow.deploy("G2", "charcoal", :pawn)
      |> :crow.deploy("H2", "charcoal", :pawn)
      |> :crow.deploy("A1", "charcoal", :rook)
      |> :crow.deploy("B1", "charcoal", :knight)
      |> :crow.deploy("C1", "charcoal", :bishop)
      |> :crow.deploy("D1", "charcoal", :queen)
      |> :crow.deploy("E1", "charcoal", :king)
      |> :crow.deploy("F1", "charcoal", :bishop)
      |> :crow.deploy("G1", "charcoal", :knight)
      |> :crow.deploy("H1", "charcoal", :rook)

    p1 = :crow.get_player(gamestate, 1)
    p2 = :crow.get_player(gamestate, 2)

    positions_p1 = :crow.get_player_positions(gamestate, p1) |> Translate.cast_positions()
    positions_p2 = :crow.get_player_positions(gamestate, p2) |> Translate.cast_positions()
    {:player, current_player} = :crow.get_current_player(gamestate)

    positions = {positions_p1, positions_p2}

    turn =
      gamestate
      |> :crow.get_turn()

    graph =
      Graph.build()
      |> Primitives.text("Turn: #{turn}", font_size: 22, translate: {25, 25}, id: :turn)
      |> Primitives.text("Current Player: #{current_player}",
        font_size: 22,
        translate: {325, 25},
        id: :current
      )
      |> Primitives.group(
        fn group ->
          group
          |> Primitives.text("bone", font_size: 22, text_align: :left, translate: {0, 0})
          |> Primitives.text("Move",
            font_size: 22,
            translate: {300, 0},
            hidden: false,
            id: :current_p1
          )
          |> Primitives.text("charcoal", font_size: 22, text_align: :left, translate: {0, 570})
          |> Primitives.text("Move",
            font_size: 22,
            translate: {300, 570},
            hidden: true,
            id: :current_p2
          )
        end,
        translate: {25, 50}
      )
      |> CrowNest.Component.Board.add_to_graph(positions, translate: {25, 60}, id: :board)

    {:ok,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:gamestate, gamestate)
     |> push_graph(graph)}
  end

  @impl Scenic.Scene
  def handle_event({:move, :board, {from_position, to_position}}, _from, scene) do
    graph = Scene.get(scene, :graph)

    {fr_x, fr_y} = from_position
    {to_x, to_y} = to_position

    gamestate =
      Scene.get(scene, :gamestate)
      |> :crow.move("#{fr_x}#{fr_y}", "#{to_x}#{to_y}")
      |> :crow.next()

    p1 = :crow.get_player(gamestate, 1)
    p2 = :crow.get_player(gamestate, 2)

    positions_p1 = :crow.get_player_positions(gamestate, p1) |> Translate.cast_positions()
    positions_p2 = :crow.get_player_positions(gamestate, p2) |> Translate.cast_positions()
    {:player, current_player} = :crow.get_current_player(gamestate)

    positions = {positions_p1, positions_p2}

    turn =
      gamestate
      |> :crow.get_turn()

    graph =
      graph
      |> Graph.modify(:turn, &Primitives.text(&1, "Turn: #{turn}"))
      |> Graph.modify(:current, &Primitives.text(&1, "Current Player: #{current_player}"))
      |> Graph.modify(
        :current_p1,
        &Primitives.update_opts(&1,
          hidden: :crow.get_player(gamestate, 1) == :crow.get_current_player(gamestate)
        )
      )
      |> Graph.modify(
        :current_p2,
        &Primitives.update_opts(&1,
          hidden: :crow.get_player(gamestate, 2) == :crow.get_current_player(gamestate)
        )
      )

    :ok = Scene.put_child(scene, :board, positions)

    {:noreply,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:gamestate, gamestate)
     |> push_graph(graph)}
  end

  def handle_event(event, from, scene) do
    Logger.info(event: inspect(event), from: from)
    {:noreply, scene}
  end
end

## Yellow / Black
# @checkered_color_a {0xc3, 0xd8, 0x6b, 0xff}
# @checkered_color_b {0x16, 0x26, 0x04, 0xff}

## Purple / Paper
# @checkered_color_a {0x62, 0x35, 0x6e, 0xff}
# @checkered_color_b {0xf6, 0xfa, 0xf9, 0xff}

## Blue / Black
# @checkered_color_a {0x0f, 0x87, 0xbb, 0xff}
# @checkered_color_b {0x1e, 0x11, 0x12, 0xff}

## Rose / Black
# @checkered_color_a {0xc3, 0x5f, 0x5c, 0xff}
# @checkered_color_b {0x03, 0x07, 0x2b, 0xff}

## Green / Avocado
# @checkered_color_a {0x5d, 0x7e, 0x22, 0xff}
# @checkered_color_b {0xfd, 0xfc, 0xe3, 0xff}

## Gameboy
# @checkered_color_a {0xcb, 0xd1, 0x14, 0xff}
# @checkered_color_b {0x24, 0x5f, 0x0c, 0xff}

## Purple / Yellow
# @checkered_color_a {0x6d, 0x57, 0x7d, 0xff}
# @checkered_color_b {0xf6, 0xed, 0xc0, 0xff}

## Blue / Green
# @checkered_color_a {0x62, 0x6d, 0x09, 0xff}
# @checkered_color_b {0xc9, 0xfe, 0xf4, 0xff}

## Blue / Brown
# @checkered_color_a {0xb8, 0xf9, 0xf2, 0xff}
# @checkered_color_b {0x80, 0x51, 0x49, 0xff}

## Blue / Purple
# @checkered_color_a {0x74, 0x61, 0xc2, 0xff}
# @checkered_color_b {0xe2, 0xf9, 0xf0, 0xff}
