defmodule ScenTest do
  use ExUnit.Case
  doctest CrowNest

  test "greets the world" do
    assert CrowNest.hello() == :world
  end
end
