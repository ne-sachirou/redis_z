defmodule RedisZTest do
  use ExUnit.Case
  doctest RedisZ

  test "greets the world" do
    assert RedisZ.hello() == :world
  end
end
