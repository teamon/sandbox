defmodule OkTest do
  use ExUnit.Case
  doctest Ok

  test "greets the world" do
    assert Ok.hello() == :world
  end
end
