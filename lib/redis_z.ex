defmodule RedisZ do
  @moduledoc """
  RedisZ - Redis Super: Full featured Redis adapter for Elixir based on Redix.
  """

  alias __MODULE__.{Diagnoser, Server, Shard, Shards, ShardsStarter}

  use Supervisor

  @type args :: [
          server_name: atom,
          shards_name: atom,
          diagnoser_name: atom,
          urls: [binary | keyword] | binary,
          pool_size: pos_integer,
          shards: [
            name: atom,
            diagnoser_name: atom,
            pool_name: atom,
            pool_size: pos_integer
          ]
        ]

  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(args) do
    args = args |> put_in([:server_name], args[:name]) |> Keyword.delete(:name)
    Supervisor.start_link(__MODULE__, args)
  end

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
  """
  @spec pipeline(atom, [Redix.command()], keyword) ::
          {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
  def pipeline(conn, commands, opts \\ []),
    do: do_pipeline(:pipeline, conn, commands, opts)

  @doc """
  """
  @spec pipeline!(atom, [Redix.command()], keyword) :: [Redix.Protocol.redis_value()] | no_return
  def pipeline!(conn, commands, opts \\ []),
    do: do_pipeline(:pipeline!, conn, commands, opts)

  @doc """
  """
  @spec command(atom, Redix.command(), keyword) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}
  def command(conn, command, opts \\ []),
    do: do_pipeline(:command, conn, command, opts)

  @doc """
  """
  @spec command!(atom, Redix.command(), keyword) :: Redix.Protocol.redis_value() | no_return
  def command!(conn, command, opts \\ []),
    do: do_pipeline(:command!, conn, command, opts)

  @doc """
  """
  @spec pipeline_to_all_shards(atom, [Redix.command()], keyword) :: %{
          atom => {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
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
    |> Enum.map(fn
      {{:ok, {:ok, values}}, shard} -> {shard[:name], {:ok, values}}
      {{:ok, {:error, reason}}, shard} -> {shard[:name], {:error, reason}}
      {reason, shard} -> {shard[:name], {:error, reason}}
    end)
    |> Enum.into(%{})
  end

  @doc """
  """
  @spec command_to_all_shards(atom, Redix.command(), keyword) :: %{
          atom => {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}
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

  @spec do_pipeline(atom, atom, [Redix.command()] | Redix.command(), keyword) :: term
  defp do_pipeline(fun_name, conn, commands, opts) do
    args = :ets.tab2list(conn)

    shard =
      if is_list(hd(commands)),
        do: Shards.assign_commands!(commands, args),
        else: Shards.assign_commands!([commands], args)

    apply(Shard, fun_name, [shard, commands, opts])
  end
end
