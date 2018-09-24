defmodule AlchemessagesTest do
  use ExUnit.Case
  doctest Alchemessages

  test "greets the world" do
    assert Alchemessages.hello() == :world
  end
end
