defmodule ScenTest do
  use ExUnit.Case
  doctest Crow

  test "greets the world" do
    assert Crow.hello() == :world
  end
end
