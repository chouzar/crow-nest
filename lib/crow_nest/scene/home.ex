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
  def handle_event(event, from, scene) do
    Logger.info(event: inspect(event), from: from)

    # :ok = Scene.put_child(scene, :board, {player_positions_a, player_positions_b})

    {:noreply, scene}
  end
end
