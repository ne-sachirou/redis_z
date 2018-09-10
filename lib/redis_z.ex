defmodule RedisZ do
  @moduledoc """
  Pooling & sharding support parallel Redis adapter base on `Redix`.

  Start RedisZ in your application.

  ```
  children = [
    {RedisZ, name: Example.Redis, pool_size: 4, urls: ["redis://localhost/0", "redis://localhost/1"]},
  ]
  ```

  Call RedisZ like Redix.

  ```
  "OK" = RedisZ.command!(Example.Redis, ["SETEX", "mykey", 10, "Hello"])
  [10, "Hello"] = RedisZ.pipeline!(Example.Redis, [["TTL", "mykey"], ["GET", "mykey"]])
  ```

  You can specify shard [like Redis Cluster](https://redis.io/topics/cluster-spec#keys-hash-tags). `{momonga}1` & `{momonga}2` are stored at the same shard.

  ```
  ["OK", "OK"] = RedisZ.pipeline!(Example.Redis, ["SET", "{momonga}1", "Hello"], ["SET", "{momonga}2", "Hello"])
  ```
  """

  alias __MODULE__.{Diagnoser, Pool, Server, Shard, Shards, ShardsStarter}

  use Supervisor

  @type args :: [
          server_name: Server.name(),
          shards_name: Shards.name(),
          diagnoser_name: Diagnoser.name(),
          urls: [binary | keyword] | binary,
          pool_size: pos_integer,
          shards: [
            name: Shard.name(),
            diagnoser_name: Diagnoser.name(),
            pool_name: Pool.name(),
            pool_size: pos_integer
          ]
        ]

  @doc false
  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(args) do
    args = args |> put_in([:server_name], args[:name]) |> Keyword.delete(:name)
    Supervisor.start_link(__MODULE__, args)
  end

  @doc false
  @spec init(keyword) :: {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  def init(args) do
    unless is_atom(args[:server_name]),
      do: raise(ArgumentError, message: "Should have is_atom(:name)")

    unless is_list(args[:urls]) or is_binary(args[:urls]),
      do: raise(ArgumentError, message: "Should have is_list(:urls) or is_binary(:urls)")

    unless is_nil(args[:pool_size]) or (is_integer(args[:pool_size]) and args[:pool_size] > 0),
      do: raise(ArgumentError, message: "Should have is_integer(:pool_size) and :pool_size > 0")

    args =
      args
      |> update_in([:urls], fn
        urls when is_binary(urls) -> String.split(urls, ~r/\s*,\s*/, trim: true)
        urls -> urls
      end)
      |> update_in([:pool_size], &(&1 || 1))
      |> put_in([:diagnoser_name], :"#{args[:server_name]}.Diagnoser")
      |> put_in([:shards_name], :"#{args[:server_name]}.Shards")

    children = [
      {Diagnoser, args},
      {Server, args},
      {Shards, args},
      {ShardsStarter, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Act like `Redix.pipeline/3` through shards & connnection pool.
  """
  @spec pipeline(Server.name(), [Redix.command()], keyword) ::
          {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
  def pipeline(conn, commands, opts \\ []),
    do: do_pipeline(:pipeline, conn, commands, opts)

  @doc """
  Act like `Redix.pipeline!/3` through shards & connnection pool.
  """
  @spec pipeline!(Server.name(), [Redix.command()], keyword) ::
          [Redix.Protocol.redis_value()] | no_return
  def pipeline!(conn, commands, opts \\ []),
    do: do_pipeline(:pipeline!, conn, commands, opts)

  @doc """
  Act like `Redix.command/3` through shards & connnection pool.
  """
  @spec command(Server.name(), Redix.command(), keyword) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}
  def command(conn, command, opts \\ []),
    do: do_pipeline(:command, conn, command, opts)

  @doc """
  Act like `Redix.command!/3` through shards & connnection pool.
  """
  @spec command!(Server.name(), Redix.command(), keyword) ::
          Redix.Protocol.redis_value() | no_return
  def command!(conn, command, opts \\ []),
    do: do_pipeline(:command!, conn, command, opts)

  @doc """
  `pipeline/3` to each shards & collect the resutls.
  """
  @spec pipeline_to_all_shards(Server.name(), [Redix.command()], keyword) :: %{
          Shard.name() => {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
        }
  def pipeline_to_all_shards(conn, commands, opts \\ []) do
    shards = :ets.lookup_element(conn, :shards, 2)

    shards
    |> Task.async_stream(
      fn shard -> Shard.pipeline(shard[:name], commands, opts) end,
      timeout: Keyword.get(opts, :timeout, 5000),
      on_timeout: :kill_task
    )
    |> Enum.zip(shards)
    |> Enum.into(%{}, fn
      {{:ok, {:ok, values}}, shard} -> {shard[:name], {:ok, values}}
      {{:ok, {:error, reason}}, shard} -> {shard[:name], {:error, reason}}
      {reason, shard} -> {shard[:name], {:error, reason}}
    end)
  end

  @doc """
  `command/3` to each shards & collect the resutls.
  """
  @spec command_to_all_shards(Server.name(), Redix.command(), keyword) :: %{
          Shard.name() => {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}
        }
  def command_to_all_shards(conn, command, opts \\ []) do
    for {shard, result} <- pipeline_to_all_shards(conn, [command], opts),
        result =
          (case result do
             {:ok, [value]} -> {:ok, value}
             error -> error
           end),
        into: %{},
        do: {shard, result}
  end

  @spec do_pipeline(atom, Server.name(), [Redix.command()] | Redix.command(), keyword) :: term
  defp do_pipeline(fun_name, conn, commands, opts) do
    args = :ets.tab2list(conn)

    shard =
      if is_list(hd(commands)),
        do: Shards.assign_commands!(commands, args),
        else: Shards.assign_commands!([commands], args)

    apply(Shard, fun_name, [shard, commands, opts])
  end
end
