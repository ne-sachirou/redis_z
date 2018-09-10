defmodule RedisZ.Shards do
  @moduledoc """
  Supervise `RedisZ.Shard` workers.
  """

  alias RedisZ.Shard

  use DynamicSupervisor

  @type name :: GenServer.server()

  @doc false
  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(args),
    do: DynamicSupervisor.start_link(__MODULE__, args, name: args[:shards_name])

  @doc false
  def init(args),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: length(args[:urls]) * 1000)

  @doc """
  """
  @spec select_shard(binary, keyword) :: Shard.name()
  def select_shard(key, args) do
    key =
      case Regex.run(~r/^[^{]*{(.+?)}/, key) do
        [_, key] -> key
        nil -> key
      end

    shards = args[:shards]
    Enum.at(shards, :erlang.phash2(key, length(shards)))[:name]
  end

  @doc """
  """
  @spec assign_commands!([Redix.command()], keyword) :: Shard.name()
  def assign_commands!(commands, args) do
    with [shard | _] <- shards = Enum.map(commands, &assign_command!(&1, args)),
         1 <- shards |> MapSet.new() |> MapSet.size() do
      shard
    else
      _ -> raise Redix.Error, "Can't assign a single shard."
    end
  end

  @spec assign_command!(Redix.command(), keyword) :: Shard.name()
  defp assign_command!(command, args) do
    keys =
      case command_keys_rule(:string.uppercase(hd(command))) do
        pos when is_integer(pos) -> [Enum.at(command, pos)]
        %Range{} = range -> Enum.slice(command, range)
        fun when is_function(fun) -> fun.(command)
        nil -> raise Redix.Error, "Can't assign #{hd(command)} to shard."
      end

    with [shard | _] <- shards = Enum.map(keys, &select_shard(&1, args)),
         1 <- shards |> MapSet.new() |> MapSet.size() do
      shard
    else
      _ -> raise Redix.Error, "Can't assign a single shard."
    end
  end

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
      "ZADD" => 1,
      "ZCARD" => 1,
      "ZCOUNT" => 1,
      "ZINCRBY" => 1,
      "ZINTERSTORE" => &command_zinterstore_keys/1,
      "ZLEXCOUNT" => 1,
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
      "OBJECT" ->
        [Enum.at(command, 2)]

      _ ->
        raise Redix.Error,
              "Can't assign #{command |> Enum.slice(0, 2) |> Enum.join(" ")} to shard."
    end
  end

  defp command_eval_keys([_, _, numkeys | _] = command), do: Enum.slice(command, 3, numkeys)

  defp command_georadius_keys(command) do
    keys = [Enum.at(command, 1)]

    keys =
      case Enum.find_index(
             command,
             &(is_binary(&1) and :string.uppercase(&1) === "STORE")
           ) do
        nil -> keys
        i -> [Enum.at(command, i + 1) | keys]
      end

    keys =
      case Enum.find_index(
             command,
             &(is_binary(&1) and :string.uppercase(&1) === "STOREDIST")
           ) do
        nil -> keys
        i -> [Enum.at(command, i + 1) | keys]
      end

    Enum.reverse(keys)
  end

  defp command_memory_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      "USAGE" ->
        [Enum.at(command, 2)]

      _ ->
        raise Redix.Error,
              "Can't assign #{command |> Enum.slice(0, 2) |> Enum.join(" ")} to shard."
    end
  end

  defp command_mset_keys(command), do: command |> tl |> Enum.chunk_every(2) |> Enum.map(&hd/1)

  defp command_object_keys(command) do
    subcommand_name = :string.uppercase(Enum.at(command, 1))

    if subcommand_name in ["REFCOUNT", "ENCODING", "IDLETIME", "FREQ"] do
      [Enum.at(command, 2)]
    else
      raise Redix.Error,
            "Can't assign #{command |> Enum.slice(0, 2) |> Enum.join(" ")} to shard."
    end
  end

  defp command_pubsub_keys(command) do
    case :string.uppercase(Enum.at(command, 1)) do
      "NUMSUB" ->
        [Enum.at(command, 2)]

      _ ->
        raise Redix.Error,
              "Can't assign #{command |> Enum.slice(0, 2) |> Enum.join(" ")} to shard."
    end
  end

  defp command_sort_keys(command) do
    keys = [Enum.at(command, 1)]

    keys =
      case Enum.find_index(
             command,
             &(is_binary(&1) and :string.uppercase(&1) === "STORE")
           ) do
        nil -> keys
        i -> [Enum.at(command, i + 1) | keys]
      end

    Enum.reverse(keys)
  end

  defp command_zinterstore_keys([_, _, numkeys | _] = command),
    do: [Enum.at(command, 1) | Enum.slice(command, 3, numkeys)]
end
