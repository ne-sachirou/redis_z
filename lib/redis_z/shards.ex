defmodule RedisZ.Shards do
  @moduledoc """
  Supervise `RedisZ.Shard` workers.
  """

  alias RedisZ.{Command, Shard}

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
    with [shard | _] <- shards = command |> Command.keys() |> Enum.map(&select_shard(&1, args)),
         1 <- shards |> MapSet.new() |> MapSet.size() do
      shard
    else
      _ -> raise Redix.Error, "Can't assign a single shard."
    end
  end
end
