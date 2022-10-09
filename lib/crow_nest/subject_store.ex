defmodule CrowNest.SessionRegistry do
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

  @impl GenServer
  def init([]) do
    table_id = :ets.new(__MODULE__, [:named_table])
    {:ok, %{table: table_id}}
  end

  @impl GenServer
  def handle_cast({:put, session, subject = {:subject, pid, _ref}}, state) do
    Process.monitor(pid)
    :ets.insert(state.table, {pid, session})
    :ets.insert(state.table, {session, subject})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, state)
      when reason in [:normal, :shutdown] do
    case :ets.lookup(__MODULE__, pid) do
      [{^pid, session}] ->
        :ets.delete(__MODULE__, pid)
        :ets.delete(__MODULE__, session)
    end

    {:noreply, state}
  end
end
