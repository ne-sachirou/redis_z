{:ok, _} =
  RedisZ.start_link(
    name: RedisZTest,
    urls: ["redis://localhost/0", "redis://localhost/1"],
    pool_size: 2
  )

Process.sleep(1000)
RedisZ.command_to_all_shards(RedisZTest, ["FLUSHDB"])
ExUnit.start()
