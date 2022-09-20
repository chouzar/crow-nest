defmodule ScenTest do
  use ExUnit.Case
  doctest Crows

  test "greets the world" do
    assert Crows.hello() == :world
  end
end
