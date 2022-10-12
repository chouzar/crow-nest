defmodule CrowNest.Scene.Home do
  use Scenic.Scene

  require Logger

  alias Scenic.Graph
  alias Scenic.Scene
  alias CrowNest.Translate

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    gamestate =
      :crow.new()
      |> :crow.players("charcoal", "bone")
      |> :crow.deploy("A3", "bone", :knight)
      |> :crow.deploy("B5", "bone", :pawn)
      |> :crow.deploy("C7", "bone", :pawn)
      |> :crow.deploy("E6", "bone", :bishop)
      |> :crow.deploy("H2", "bone", :king)
      |> :crow.deploy("F8", "bone", :queen)
      |> :crow.deploy("D4", "charcoal", :knight)

    positions =
      gamestate
      |> :crow.get_positions()
      |> Translate.cast_positions()

    player_positions_a =
      Map.filter(positions, fn {_position, check} -> check.player == "charcoal" end)

    player_positions_b =
      Map.filter(positions, fn {_position, check} -> check.player == "bone" end)

    graph =
      Graph.build()
      |> CrowNest.Component.Board.add_to_graph({player_positions_a, player_positions_b},
        id: :board,
        translate: {25, 25}
      )

    {:ok,
     scene
     |> Scene.assign(:graph, graph)
     |> Scene.assign(:gamestate, gamestate)
     |> push_graph(graph)}
  end

  @impl Scenic.Scene
  def handle_event({:move, :board, {from_position, to_position}}, _from, scene) do
    {fr_x, fr_y} = from_position
    {to_x, to_y} = to_position

    gamestate =
      Scene.get(scene, :gamestate)
      |> :crow.move("#{fr_x}#{fr_y}", "#{to_x}#{to_y}")

    positions =
      gamestate
      |> :crow.get_positions()
      |> Translate.cast_positions()

    player_positions_a =
      Map.filter(positions, fn {_position, check} -> check.player == "charcoal" end)

    player_positions_b =
      Map.filter(positions, fn {_position, check} -> check.player == "bone" end)

    :ok = Scene.put_child(scene, :board, {player_positions_a, player_positions_b})

    {:noreply,
     scene
     |> Scene.assign(:gamestate, gamestate)}
  end

  def handle_event(event, from, scene) do
    Logger.info(event: inspect(event), from: from)
    {:noreply, scene}
  end
end
