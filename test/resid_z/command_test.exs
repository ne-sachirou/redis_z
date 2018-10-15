defmodule RedisZ.CommandTest do
  alias RedisZ.Command

  use ExUnit.Case

  doctest Command

  describe "keys/1" do
    for command <- [
          ["APPEND", "key", "value"],
          ["BITCOUNT", "key"],
          ["BITFIELD", "key", "GET", "i5", 42],
          ["BITPOS", "key", 42],
          ["DEBUG", "OBJECT", "key"],
          ["DECR", "key"],
          ["DECRBY", "key", 42],
          ["DEL", "key"],
          ["DUMP", "key"],
          ["EVAL", "return redis.call('GET', KEYS[1])", 1, "key"],
          ["EVALSHA", "0e293e9a0ad1c7cec8ed50cb19bc31d254fd328f", 1, "key"],
          ["EXISTS", "key"],
          ["EXPIRE", "key", 42],
          ["EXPIREAT", "key", 0],
          ["GEOADD", "key", 0, 0, "member"],
          ["GEODIST", "key", "member1", "member2"],
          ["GEOHASH", "key", "member"],
          ["GEOPOS", "key", "member"],
          ["GEORADIUS", "key", 0, 0, 42, "m"],
          ["GEORADIUSBYMEMBER", "key", 0, 0, 42, "m"],
          ["GET", "key"],
          ["GETBIT", "key", 42],
          ["GETRANGE", "key", 0, 42],
          ["GETSET", "key", "value"],
          ["HDEL", "key", "field"],
          ["HEXISTS", "key", "field"],
          ["HGET", "key", "field"],
          ["HGETALL", "key"],
          ["HINCRBY", "key", "field", 42],
          ["HINCRBYFLOAT", "key", "field", 4.2],
          ["HKEYS", "key"],
          ["HLEN", "key"],
          ["HMGET", "key", "field"],
          ["HMSET", "key", "field", "value"],
          ["HSCAN", "key", 0],
          ["HSET", "key", "field", "value"],
          ["HSETNX", "key", "field", "value"],
          ["HSTRLEN", "key", "field"],
          ["HVALS", "key"],
          ["INCR", "key"],
          ["INCRBY", "key", 42],
          ["INCRBYFLOAT", "key", 4.2],
          ["LINDEX", "key", 42],
          ["LINSERT", "key", "BEFORE", "pivot", "value"],
          ["LLEN", "key"],
          ["LPOP", "key"],
          ["LPUSH", "key", "value"],
          ["LPUSHX", "key", "value"],
          ["LRANGE", "key", 0, 42],
          ["LREM", "key", 42, "value"],
          ["LSET", "key", 42, "value"],
          ["LTRIM", "key", 0, 42],
          ["MEMORY", "USAGE", "key"],
          ["MGET", "key"],
          ["MOVE", "key", 0],
          ["MSET", "key", "value"],
          ["MSETNX", "key", "value"],
          ["OBJECT", "REFCOUNT", "key"],
          ["OBJECT", "ENCODING", "key"],
          ["OBJECT", "IDLETIME", "key"],
          ["OBJECT", "FREQ", "key"],
          ["PERSIST", "key"],
          ["PEXPIRE", "key", 42_000],
          ["PEXPIREAT", "key", 0],
          ["PFADD", "key", "element"],
          ["PFCOUNT", "key"],
          ["PSETEX", "key", 42_000, "value"],
          ["PTTL", "key"],
          ["PUBSUB", "NUMSUB", "key"],
          ["RESTORE", "key", 0, "serialized-value"],
          ["RPOP", "key"],
          ["RPUSH", "key", "value"],
          ["RPUSHX", "key", "value"],
          ["SADD", "key", "member"],
          ["SCARD", "key"],
          ["SDIFF", "key"],
          ["SET", "key", "value"],
          ["SETBIT", "key", 42, 1],
          ["SETEX", "key", 42, "value"],
          ["SETNX", "key", "value"],
          ["SETRANGE", "key", 42, "value"],
          ["SINTER", "key"],
          ["SISMEMBER", "key", "member"],
          ["SMEMBERS", "key"],
          ["SORT", "key"],
          ["SPOP", "key"],
          ["SRANDMEMBER", "key"],
          ["SREM", "key", "member"],
          ["SSCAN", "key", 0],
          ["STRLEN", "key"],
          ["SUNION", "key"],
          ["TOUCH", "key"],
          ["TTL", "key"],
          ["TYPE", "key"],
          ["UNLINK", "key"],
          ["XADD", "key", "ID", "*", "field", "value"],
          ["XLEN", "key"],
          ["XPENDING", "key", "group"],
          ["XRANGE", "key", "-", "+"],
          ["XREAD", "STREAMS", "key", "id"],
          ["XREADGROUP", "GROUP", "group", "consumer", "STREAMS", "key", "id"],
          ["XREVRANGE", "key", "+", "-"],
          ["ZADD", "key", 42, "member"],
          ["ZCARD", "key"],
          ["ZCOUNT", "key", "-inf", "+inf"],
          ["ZINCRBY", "key", 42, "member"],
          ["ZLEXCOUNT", "key", "-", "+"],
          ["ZPOPMAX", "key"],
          ["ZPOPMIN", "key"],
          ["ZRANGE", "key", 0, 42],
          ["ZRANGEBYLEX", "key", "[a", "[b"],
          ["ZRANGEBYSCORE", "key", "-inf", "+inf"],
          ["ZRANK", "key", "member"],
          ["ZREM", "key", "member"],
          ["ZREMRANGEBYLEX", "key", "[a", "[b"],
          ["ZREMRANGEBYRANK", "key", 0, 42],
          ["ZREMRANGEBYSCORE", "key", "-inf", "+inf"],
          ["ZREVRANGE", "key", 0, 42],
          ["ZREVRANGEBYLEX", "key", "[a", "[b"],
          ["ZREVRANGEBYSCORE", "key", "-inf", "+inf"],
          ["ZREVRANK", "key", "member"],
          ["ZSCAN", "key", 0],
          ["ZSCORE", "key", "member"]
        ] do
      @tag command: command
      test(Enum.join(command, " "), %{command: command},
        do: assert(["key"] == Command.keys(command))
      )
    end

    for command <- [
          ["BITOP", "NOT", "key1", "key2"],
          ["DEL", "key1", "key2"],
          ["EVAL", "return redis.call('SET', KEYS[1], ARGV[1])", 2, "key1", "key2", "arg"],
          ["EVALSHA", "0e293e9a0ad1c7cec8ed50cb19bc31d254fd328f", 2, "key1", "key2", "arg"],
          ["EXISTS", "key1", "key2"],
          ["GEORADIUS", "key1", 0, 0, 42, "m", "STORE", "key2"],
          ["GEORADIUS", "key1", 0, 0, 42, "m", "STOREDIST", "key2"],
          ["MGET", "key1", "key2"],
          ["MSET", "key1", "value1", "key2", "value2"],
          ["MSETNX", "key1", "value1", "key2", "value2"],
          ["PFCOUNT", "key1", "key2"],
          ["PFMERGE", "key1", "key2"],
          ["PUBSUB", "NUMSUB", "key1", "key2"],
          ["RENAME", "key1", "key2"],
          ["RENAMENX", "key1", "key2"],
          ["RPOPLPUSH", "key1", "key2"],
          ["SDIFF", "key1", "key2"],
          ["SDIFFSTORE", "key1", "key2"],
          ["SINTER", "key1", "key2"],
          ["SINTERSTORE", "key1", "key2"],
          ["SMOVE", "key1", "key2", "member"],
          ["SORT", "key1", "STORE", "key2"],
          ["SUNION", "key1", "key2"],
          ["SUNIONSTORE", "key1", "key2"],
          ["TOUCH", "key1", "key2"],
          ["UNLINK", "key1", "key2"],
          ["ZINTERSTORE", "key1", 1, "key2"],
          ["ZUNIONSTORE", "key1", 1, "key2"]
        ] do
      @tag command: command
      test(Enum.join(command, " "), %{command: command},
        do: assert(~w(key1 key2) == Command.keys(command))
      )
    end

    for command <- [
          ["AUTH", "password"],
          ["BGREWRITEAOF"],
          ["BGSAVE"],
          ["BLPOP", "key", 0],
          ["BRPOP", "key", 0],
          ["BRPOPLPUSH", "key1", "key2", 0],
          ["BZPOPMAX", "key", 0],
          ["BZPOPMIN", "key", 0],
          ["CLIENT", "GETNAME"],
          ["CLIENT", "KILL"],
          ["CLIENT", "LIST"],
          ["CLIENT", "PAUSE", 42],
          ["CLIENT", "REPLY", "ON"],
          ["CLIENT", "SETNAME", "connection-name"],
          ["CLUSTER", "ADDSLOTS", 1],
          ["CLUSTER", "COUNT-FAILURE-REPORTS", "f9168bf7c56b1b94f7b728f104bf65f27059cb4e"],
          ["CLUSTER", "COUNTKEYSINSLOT", 1],
          ["CLUSTER", "DELSLOTS", 1],
          ["CLUSTER", "FAILOVER", "FORCE"],
          ["CLUSTER", "FORGET", "f9168bf7c56b1b94f7b728f104bf65f27059cb4e"],
          ["CLUSTER", "GETKEYSINSLOT", 1],
          ["CLUSTER", "INFO"],
          ["CLUSTER", "KEYSLOT", "key"],
          ["CLUSTER", "MEET", "127.0.0.1", 6379],
          ["CLUSTER", "NODES"],
          ["CLUSTER", "REPLICATE", "f9168bf7c56b1b94f7b728f104bf65f27059cb4e"],
          ["CLUSTER", "RESET", "HARD"],
          ["CLUSTER", "SAVECONFIG"],
          ["CLUSTER", "SET-CONFIG-EPOCH", 1],
          ["CLUSTER", "SETSLOT", 1, "IMPORTING"],
          ["CLUSTER", "SLAVES", "f9168bf7c56b1b94f7b728f104bf65f27059cb4e"],
          ["CLUSTER", "SLOTS"],
          ["COMMAND"],
          ["COMMAND", "COUNT"],
          ["COMMAND", "GETKEYS"],
          ["COMMAND", "INFO", "get"],
          ["CONFIG", "GET", "protected-mode"],
          ["CONFIG", "RESETSTAT"],
          ["CONFIG", "REWRITE"],
          ["CONFIG", "SET", "protected-mode", "no"],
          ["DBSIZE"],
          ["DEBUG", "SEGFAULT"],
          ["DISCARD"],
          ["ECHO", "message"],
          ["EXEC"],
          ["FLUSHALL"],
          ["FLUSHDB"],
          ["INFO"],
          ["KEYS"],
          ["LASTSAVE"],
          ["MEMORY", "DOCTOR"],
          ["MEMORY", "HELP"],
          ["MEMORY", "MALLOC-STATS"],
          ["MEMORY", "PURGE"],
          ["MEMORY", "STATS"],
          ["MIGRATE", "127.0.0.1", 6379, "", 0, 5000, "KEYS", "key"],
          ["MONITOR"],
          ["MULTI"],
          ["OBJECT", "HELP"],
          ["PING"],
          ["PSUBSCRIBE", "*"],
          ["PUBLISH", "key", "message"],
          ["PUBSUB", "CHANNELS", "*"],
          ["PUBSUB", "NUMPAT"],
          ["PUNSUBSCRIBE", "*"],
          ["QUIT"],
          ["RANDOMKEY"],
          ["READONLY"],
          ["READWRITE"],
          ["ROLE"],
          ["SAVE"],
          ["SCAN", 0],
          ["SCRIPT", "DEBUG", "YES"],
          ["SCRIPT", "EXISTS", "0e293e9a0ad1c7cec8ed50cb19bc31d254fd328f"],
          ["SCRIPT", "FLUSH"],
          ["SCRIPT", "KILL"],
          ["SCRIPT", "LOAD", "return redis.call('GET', KEYS[1])"],
          ["SELECT", 0],
          ["SHUTDOWN"],
          ["SLAVEOF", "127.0.0.1", 6379],
          ["SLOWLOG", "GET", 42],
          ["SLOWLOG", "LEN"],
          ["SLOWLOG", "RESET"],
          ["SUBSCRIBE", "key"],
          ["SWAPDB", 0, 1],
          ["SYNC"],
          ["TIME"],
          ["UNSUBSCRIBE", "key"],
          ["UNWATCH"],
          ["WAIT", 1, 100],
          ["WATCH", "key"]
        ] do
      @tag command: command
      test(Enum.join(command, " "), %{command: command},
        do: assert_raise(Redix.Error, fn -> Command.keys(command) end)
      )
    end
  end
end