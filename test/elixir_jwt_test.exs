defmodule ElixirJwtTest do
  use ExUnit.Case
  doctest ElixirJwt

  test "greets the world" do
    assert ElixirJwt.hello() == :world
  end
end
