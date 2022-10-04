defmodule CrowNest.SubjectStore do
  @moduledoc """
  Temporarily stores gleam subject references, so we can retrieve the full
  actor's subject to communicate with them.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put(session, subject) do
    GenServer.cast(__MODULE__, {:put, session, subject})
  end

  def get(session) do
    case :ets.lookup(__MODULE__, session) do
      [{^session, subject}] -> subject
    end
  end

  @impl true
  def init([]) do
    table_id = :ets.new(__MODULE__, [:named_table])
    {:ok, %{table: table_id}}
  end

  @impl true
  def handle_cast({:put, session, subject = {:subject, _pid, _ref}}, state) do
    :ets.insert(state.table, {session, subject})
    {:noreply, state}
  end
end
