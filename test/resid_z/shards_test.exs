defmodule RedisZTest.Shards do
  alias RedisZ.Shards

  use ExUnitProperties
  use ExUnit.Case

  doctest Shards

  describe "select_shard/2" do
    test """
    The two keys {user1000}.following and {user1000}.followers will hash to the same hash slot since only the
    substring user1000 will be hashed in order to compute the hash slot.
    """ do
      args = [shards: [[name: A], [name: B]]]

      assert Shards.select_shard("{user1000}.following", args) ===
               Shards.select_shard("{user1000}.followers", args)
    end

    # test """
    # For the key foo{}{bar} the whole key will be hashed as usually since the first occurrence of { is followed by }
    # on the right without characters in the middle.
    # """ do
    # end

    test """
    For the key foo{{bar}}zap the substring {bar will be hashed, because it is the substring between the first
    occurrence of { and the first occurrence of } on its right.
    """ do
      args = [shards: [[name: A], [name: B]]]
      assert Shards.select_shard("{bar", args) === Shards.select_shard("foo{{bar}}zap", args)
    end

    test """
    For the key foo{bar}{zap} the substring bar will be hashed, since the algorithm stops at the first valid or
    invalid (without bytes inside) match of { and }.
    """ do
      args = [shards: [[name: A], [name: B]]]
      assert Shards.select_shard("bar", args) === Shards.select_shard("foo{bar}{zap}", args)
    end

    # test """
    # What follows from the algorithm is that if the key starts with {}, it is guaranteed to be hashed as a whole.
    # This is useful when using binary data as key names.
    # """ do
    # end

    property "Simple hash tags" do
      args = [shards: [[name: A], [name: B]]]

      check all part <- string(:printable),
                part !== "",
                not String.contains?(part, ["{", "}"]),
                key = "#{part}{#{part}}#{part}" do
        assert Shards.select_shard(part, args) === Shards.select_shard(key, args)
      end
    end
  end

  describe "assign_commands!/2" do
    test "GET" do
      args = [shards: [[name: A], [name: B]]]
      assert Shards.select_shard("a", args) === Shards.assign_commands!([["GET", "a"]], args)
    end

    test "MGET" do
      args = [shards: [[name: A], [name: B]]]

      assert Shards.select_shard("a", args) ===
               Shards.assign_commands!([["MGET", "{a}x", "{a}y"]], args)
    end

    test "MGET for different shards" do
      args = [shards: [[name: A], [name: B]]]
      assert_raise Redix.Error, fn -> Shards.assign_commands!([["MGET", "ax", "ay"]], args) end
    end

    test "EVAL" do
      args = [shards: [[name: A], [name: B]]]

      assert Shards.select_shard("a", args) ===
               Shards.assign_commands!([["EVAL", "", 2, "{a}x", "{a}y", "b"]], args)
    end

    test "EVAL for different shards" do
      args = [shards: [[name: A], [name: B]]]

      assert_raise Redix.Error, fn ->
        Shards.assign_commands!([["EVAL", "", 2, "{a}x", "{h}x", "b"]], args)
      end
    end

    test "Pipeline" do
      args = [shards: [[name: A], [name: B]]]

      assert Shards.select_shard("a", args) ===
               Shards.assign_commands!([["GET", "x{a}"], ["GET", "z{a}"]], args)
    end

    test "Pipeline for different shards" do
      args = [shards: [[name: A], [name: B]]]

      assert_raise Redix.Error, fn ->
        Shards.assign_commands!([["GET", "xa"], ["GET", "za"]], args)
      end
    end
  end
end
