defmodule Crows.Scene.Home do
  use Scenic.Scene

  require Logger

  alias Scenic.Graph
  alias Scenic.Scene
  alias Crows.Component.Board

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    graph =
      Graph.build()
      |> Crows.Component.Board.add_to_graph(%{}, translate: {25, 25}, id: :the_board)

    {:ok,
     scene
     |> Scene.assign(:graph, graph)
     |> push_graph(graph)}
  end

  @impl Scenic.Scene
  # This receives simple notifications and handles a UI state machine
  # Scenes themselves do the work of drawing.
  def handle_event({type, id, value}, from, scene) do
    # IO.inspect(from, label: :board_component)
    # IO.inspect(scene, label: :home_scene)
    Logger.info(id: id, type: type, value: value)

    Scene.get(scene, :graph)
    |> Graph.modify(:the_board, fn board -> board end)

    Scene.fetch_child(scene, :the_board) |> IO.inspect(label: :fetch)
    Scene.get_child(scene, :the_board) |> IO.inspect(label: :get)
    Scene.put_child(scene, :the_board, :test) |> IO.inspect(label: :put)

    #{:ok, [pid]} = Scene.child(scene, :the_board)
    #GenServer.call(pid, :test)

    {:noreply, scene}
  end

  # @spec highlight(list(Board.position)) :: :ok
  # defp highlight(scene, positions)s do
  #  Scene.put_child(scene, :the_board, :test) |> IO.inspect(label: :put)
  #  :ok
  # end
end
