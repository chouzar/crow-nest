defmodule CrowNest do
  @moduledoc false

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:crow_nest, :viewport)

    # start the application with the viewport
    children = [
      {Scenic,
       [
         main_viewport_config
       ]},
      {DynamicSupervisor, strategy: :one_for_one, name: SessionSupervisor},
      CrowNest.SessionRegistry
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule CrowNest.Translate do
  def cast_positions(positions) do
    Map.new(positions, fn {coordinate, check} ->
      {cast_coordinate(coordinate), cast_check(check)}
    end)
  end

  def cast_check(check) do
    {:check, can_move, {:player, player}, piece, path, captures} = check
    path = Enum.map(path, &cast_coordinate/1)
    captures = Enum.map(captures, &cast_coordinate/1)
    %{can_move: can_move, player: player, piece: piece, path: path, captures: captures}
  end

  defp cast_coordinate({:coordinate, x, y}), do: {x, y}
end
