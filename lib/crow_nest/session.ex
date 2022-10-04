defmodule CrowNest.Session do
  @moduledoc """
  Wraps the session actor from `crow` library.
  """

  use DynamicSupervisor

  alias CrowNest.SubjectStore

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def new(name) do
    DynamicSupervisor.start_child(SessionSupervisor, %{
      id: {__MODULE__, name},
      start: {__MODULE__, :start, [name]}
    })
  end

  def stop(name) do
    name |> SubjectStore.get() |> :session.close()
  end

  def start(name) do
    case :session.start(name) do
      {:ok, subject = {:subject, pid, _ref}} ->
        SubjectStore.put(name, subject)
        {:ok, pid}

      error ->
        error
    end
  end

  def join(name, player), do: name |> SubjectStore.get() |> :session.join(player)
  def update(name, state), do: name |> SubjectStore.get() |> :session.update(state)
  def close(name), do: name |> SubjectStore.get() |> :session.close()
  def get_players(name), do: name |> SubjectStore.get() |> :session.get_players()
  def get_game(name), do: name |> SubjectStore.get() |> :session.get_game()

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
