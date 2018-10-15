{:ok, _} =
  RedisZ.start_link(
    name: RedisZTest,
    urls: ["redis://localhost:6379/0", "redis://localhost:6379/1"],
    pool_size: 2
  )

Process.sleep(100)
RedisZ.command_to_all_shards(RedisZTest, ["FLUSHDB"])
ExUnit.start()
