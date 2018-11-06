defmodule RedisZ.Command do
  @moduledoc """
  Parse Redis command.
  """

  @doc """
  KEYs of the command.
  """
  @spec keys(Redix.command()) :: [binary] | no_return
  def keys(command) do
    case command_keys_rule(:string.uppercase(hd(command))) do
      pos when is_integer(pos) -> [Enum.at(command, pos)]
      %Range{} = range -> Enum.slice(command, range)
      fun when is_function(fun) -> fun.(command)
      nil -> raise Redix.Error, "Can't assign #{hd(command)} to shard."
    end
  end

  @spec command_keys_rule(binary) :: pos_integer | Range.t() | (Redix.command() -> [binary]) | nil
  defp command_keys_rule(command_name) do
    %{
      "APPEND" => 1,
      "BITCOUNT" => 1,
      "BITFIELD" => 1,
      "BITOP" => 2..-1,
      "BITPOS" => 1,
      "DEBUG" => &command_debug_keys/1,
      "DECR" => 1,
      "DECRBY" => 1,
      "DEL" => 1..-1,
      "DUMP" => 1,
      "EVAL" => &command_eval_keys/1,
      "EVALSHA" => &command_eval_keys/1,
      "EXISTS" => 1..-1,
      "EXPIRE" => 1,
      "EXPIREAT" => 1,
      "GEOADD" => 1,
      "GEOHASH" => 1,
      "GEOPOS" => 1,
      "GEODIST" => 1,
      "GEORADIUS" => &command_georadius_keys/1,
      "GEORADIUSBYMEMBER" => &command_georadius_keys/1,
      "GET" => 1,
      "GETBIT" => 1,
      "GETRANGE" => 1,
      "GETSET" => 1,
      "HDEL" => 1,
      "HEXISTS" => 1,
      "HGET" => 1,
      "HGETALL" => 1,
      "HINCRBY" => 1,
      "HINCRBYFLOAT" => 1,
      "HKEYS" => 1,
      "HLEN" => 1,
      "HMGET" => 1,
      "HMSET" => 1,
      "HSET" => 1,
      "HSETNX" => 1,
      "HSTRLEN" => 1,
      "HVALS" => 1,
      "INCR" => 1,
      "INCRBY" => 1,
      "INCRBYFLOAT" => 1,
      "LINDEX" => 1,
      "LINSERT" => 1,
      "LLEN" => 1,
      "LPOP" => 1,
      "LPUSH" => 1,
      "LPUSHX" => 1,
      "LRANGE" => 1,
      "LREM" => 1,
      "LSET" => 1,
      "LTRIM" => 1,
      "MEMORY" => &command_memory_keys/1,
      "MGET" => 1..-1,
      "MOVE" => 1,
      "MSET" => &command_mset_keys/1,
      "MSETNX" => &command_mset_keys/1,
      "OBJECT" => &command_object_keys/1,
      "PERSIST" => 1,
      "PEXPIRE" => 1,
      "PEXPIREAT" => 1,
      "PFADD" => 1,
      "PFCOUNT" => 1..-1,
      "PFMERGE" => 1..-1,
      "PSETEX" => 1,
      "PUBSUB" => &command_pubsub_keys/1,
      "PTTL" => 1,
      "RENAME" => 1..2,
      "RENAMENX" => 1..2,
      "RESTORE" => 1,
      "RPOP" => 1,
      "RPOPLPUSH" => 1..2,
      "RPUSH" => 1,
      "RPUSHX" => 1,
      "SADD" => 1,
      "SCARD" => 1,
      "SDIFF" => 1..-1,
      "SDIFFSTORE" => 1..-1,
      "SET" => 1,
      "SETBIT" => 1,
      "SETEX" => 1,
      "SETNX" => 1,
      "SETRANGE" => 1,
      "SINTER" => 1..-1,
      "SINTERSTORE" => 1..-1,
      "SISMEMBER" => 1,
      "SMEMBERS" => 1,
      "SMOVE" => 1..2,
      "SORT" => &command_sort_keys/1,
      "SPOP" => 1,
      "SRANDMEMBER" => 1,
      "SREM" => 1,
      "STRLEN" => 1,
      "SUNION" => 1..-1,
      "SUNIONSTORE" => 1..-1,
      "TOUCH" => 1..-1,
      "TTL" => 1..-1,
      "TYPE" => 1..-1,
      "UNLINK" => 1..-1,
      "XADD" => 1,
      "XLEN" => 1,
      "XPENDING" => 1,
      "XRANGE" => 1,
      "XREAD" => &command_xread_keys/1,
      "XREADGROUP" => &command_xread_keys/1,
      "XREVRANGE" => 1,
      "ZADD" => 1,
      "ZCARD" => 1,
      "ZCOUNT" => 1,
      "ZINCRBY" => 1,
      "ZINTERSTORE" => &command_zinterstore_keys/1,
      "ZLEXCOUNT" => 1,
      "ZPOPMAX" => 1,
      "ZPOPMIN" => 1,
      "ZRANGE" => 1,
      "ZRANGEBYLEX" => 1,
      "ZREVRANGEBYLEX" => 1,
      "ZRANGEBYSCORE" => 1,
      "ZRANK" => 1,
      "ZREM" => 1,
      "ZREMRANGEBYLEX" => 1,
      "ZREMRANGEBYRANK" => 1,
      "ZREMRANGEBYSCORE" => 1,
      "ZREVRANGE" => 1,
      "ZREVRANGEBYSCORE" => 1,
      "ZREVRANK" => 1,
      "ZSCORE" => 1,
      "ZUNIONSTORE" => &command_zinterstore_keys/1,
      "SSCAN" => 1,
      "HSCAN" => 1,
      "ZSCAN" => 1
    }[command_name]
  end

  defp command_debug_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      "OBJECT" -> [Enum.at(command, 2)]
      subcommand -> raise Redix.Error, "Can't assign #{hd(command)} #{subcommand} to shard."
    end
  end

  defp command_eval_keys([_, _, numkeys | _] = command), do: Enum.slice(command, 3, numkeys)

  defp command_georadius_keys(command) do
    keys = [Enum.at(command, 1)]

    keys =
      case followings_on(command, "STORE") do
        [] -> keys
        [key | _] -> [key | keys]
      end

    keys =
      case followings_on(command, "STOREDIST") do
        [] -> keys
        [key | _] -> [key | keys]
      end

    Enum.reverse(keys)
  end

  defp command_memory_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      "USAGE" -> [Enum.at(command, 2)]
      subcommand -> raise Redix.Error, "Can't assign #{hd(command)} #{subcommand} to shard."
    end
  end

  defp command_mset_keys(command), do: command |> tl |> Enum.chunk_every(2) |> Enum.map(&hd/1)

  defp command_object_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      subcommand when subcommand in ["REFCOUNT", "ENCODING", "IDLETIME", "FREQ"] ->
        [Enum.at(command, 2)]

      subcommand ->
        raise Redix.Error, "Can't assign #{hd(command)} #{subcommand} to shard."
    end
  end

  defp command_pubsub_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      "NUMSUB" -> Enum.slice(command, 2..-1)
      subcommand -> raise Redix.Error, "Can't assign #{hd(command)} #{subcommand} to shard."
    end
  end

  defp command_sort_keys(command) do
    keys = [Enum.at(command, 1)]

    keys =
      case followings_on(command, "STORE") do
        [] -> keys
        [key | _] -> [key | keys]
      end

    Enum.reverse(keys)
  end

  defp command_xread_keys(command) do
    case followings_on(command, "STREAMS") do
      [] ->
        raise Redix.Error, "Can't assign #{Enum.join(command, " ")} to shard."

      keys_and_ids when rem(length(keys_and_ids), 2) == 0 ->
        Enum.slice(keys_and_ids, 0, keys_and_ids |> length |> div(2))

      _ ->
        raise Redix.Error, "Can't assign #{Enum.join(command, " ")} to shard."
    end
  end

  defp command_zinterstore_keys([_, _, numkeys | _] = command),
    do: [Enum.at(command, 1) | Enum.slice(command, 3, numkeys)]

  @spec followings_on(Redix.command(), binary) :: [binary]
  defp followings_on(command, token) do
    case Enum.drop_while(command, &(not (is_binary(&1) and :string.uppercase(&1) == token))) do
      [^token | rest] -> rest
      _ -> []
    end
  end
end
