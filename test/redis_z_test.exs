defmodule RedisZTest do
  use ExUnit.Case

  doctest RedisZ

  describe "pipeline/3" do
    test "SET & GET" do
      key = "redis_z_test_1"
      assert {:ok, ["OK", "42"]} === RedisZ.pipeline(RedisZTest, [["SET", key, 42], ["GET", key]])
    end
  end

  describe "command/3" do
    test "SET & GET" do
      key = "redis_z_test_2"
      assert {:ok, "OK"} === RedisZ.command(RedisZTest, ["SET", key, 42])
      assert {:ok, "42"} === RedisZ.command(RedisZTest, ["GET", key])
    end
  end

  describe "pipeline_to_all_shards/3" do
    test "PING" do
      assert %{
               "Elixir.RedisZTest.Shards.1": {:ok, ["PONG"]},
               "Elixir.RedisZTest.Shards.2": {:ok, ["PONG"]}
             } === RedisZ.pipeline_to_all_shards(RedisZTest, [["PING"]])
    end
  end

  describe "command_to_all_shards/3" do
    test "PING" do
      assert %{
               "Elixir.RedisZTest.Shards.1": {:ok, "PONG"},
               "Elixir.RedisZTest.Shards.2": {:ok, "PONG"}
             } === RedisZ.command_to_all_shards(RedisZTest, [["PING"]])
    end
  end
end
