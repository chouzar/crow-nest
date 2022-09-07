defmodule ScenTest do
  use ExUnit.Case
  doctest Scen

  test "greets the world" do
    assert Scen.hello() == :world
  end
end
