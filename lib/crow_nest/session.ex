defmodule CrowNest.Session do
  @moduledoc """
  Wraps the session actor from `crow` library.
  """

  use DynamicSupervisor

  alias CrowNest.SessionRegistry

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def new(name) do
    DynamicSupervisor.start_child(SessionSupervisor, %{
      id: {__MODULE__, name},
      start: {__MODULE__, :start, [name]},
      restart: :transient
    })
  end

  def stop(name) do
    name |> SessionRegistry.get() |> :session.close()
  end

  def start(name) do
    case :session.start(name) do
      {:ok, subject = {:subject, pid, _ref}} ->
        SessionRegistry.put(name, subject)
        {:ok, pid}

      error ->
        error
    end
  end

  def join(name, player), do: name |> SessionRegistry.get() |> :session.join(player)
  def update(name, state), do: name |> SessionRegistry.get() |> :session.update(state)
  def close(name), do: name |> SessionRegistry.get() |> :session.close()
  def get_players(name), do: name |> SessionRegistry.get() |> :session.get_players()
  def get_game(name), do: name |> SessionRegistry.get() |> :session.get_game()

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
