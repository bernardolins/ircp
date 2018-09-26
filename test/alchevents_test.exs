defmodule IRCPTest do
  use ExUnit.Case
  doctest IRCP

  test "greets the world" do
    assert IRCP.hello() == :world
  end
end
