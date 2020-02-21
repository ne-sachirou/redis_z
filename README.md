[![Actions Status](https://github.com/ne-sachirou/redis_z/workflows/test/badge.svg)](https://github.com/ne-sachirou/redis_z/actions)
[![Coverage Status](https://coveralls.io/repos/github/ne-sachirou/redis_z/badge.svg)](https://coveralls.io/github/ne-sachirou/redis_z)
[![Hex.pm](https://img.shields.io/hexpm/v/redis_z.svg)](https://hex.pm/packages/redis_z)

# RedisZ - Redis Super

Pooling & sharding support parallel Redis adapter base on [Redix][redix].

- No downgrade from Redix: pipeline concurrency & auto reconnection.
- [Parallel connection pooling](https://hexdocs.pm/redix/real-world-usage.html).
- Sharding support.
- [Auto reconnect at Amazon ElastiCache Multi-AZ failover.](https://rubygems.org/gems/redis-elasticache)

## Usage

Start RedisZ in your application.

```elixir
defmodule Example.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {RedisZ, name: Example.Redis, pool_size: 4, urls: ["redis://localhost/0", "redis://localhost/1"]},
    ]

    opts = [strategy: :one_for_one, name: Orange.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Call RedisZ like Redix.

```elixir
"OK" = RedisZ.command!(Example.Redis, ["SETEX", "mykey", 10, "Hello"])
[10, "Hello"] = RedisZ.pipeline!(Example.Redis, [["TTL", "mykey"], ["GET", "mykey"]])
```

You can specify shard [like Redis Cluster](https://redis.io/topics/cluster-spec#keys-hash-tags). `{momonga}1` & `{momonga}2` are stored at the same shard.

```elixir
["OK", "OK"] = RedisZ.pipeline!(Example.Redis, ["SET", "{momonga}1", "Hello"], ["SET", "{momonga}2", "Hello"])
```

## Installation

Add `:redis_z` at `mix.exs`.

```elixir
def deps do
  [
    {:redis_z, "~> 0.3"}
  ]
end
```

## Architecture

![processes](https://github.com/ne-sachirou/redis_z/raw/master/processes.png)

## TODO

- [ ] Redis sentinel support.
- [ ] Redis cluster support.
- [ ] Online resharding.
- [ ] Controll connection pool size dynamically.
- [ ] Support commands for multiple shards.
- [ ] MULTI EXEC support.
- [ ] BLPOP BRPOP BRPOPLPUSH support.
- [ ] SCAN support
- [ ] ~~PubSub support.~~ Use [Redix.PubSub][redix.pubsub] & [Phoenix.PubSub.RedisZ][phoenix.pubsub.redisz].

[redix]: https://hex.pm/packages/redix
[redix.pubsub]: https://hex.pm/packages/redix_pubsub
[phoenix.pubsub.redisz]: https://hex.pm/packages/phoenix_pubsub_redis_z
