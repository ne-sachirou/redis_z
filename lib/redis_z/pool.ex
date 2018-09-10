defmodule RedisZ.Pool do
  @moduledoc """
  Parallel & concurrent Redix connection pool.

  cf. [https://hexdocs.pm/redix/real-world-usage.html](https://hexdocs.pm/redix/real-world-usage.html)
  """

  use DynamicSupervisor

  @type name :: Supervisor.supervisor()

  @doc false
  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(args), do: DynamicSupervisor.start_link(__MODULE__, args, name: args[:pool_name])

  @doc false
  def init(args),
    do: DynamicSupervisor.init(strategy: :one_for_one, max_restarts: args[:pool_size] * 1000)

  @doc """
  Get a random Redix connection from the pool.
  """
  @spec get_conn(name, non_neg_integer) :: atom
  def get_conn(pool_name, pool_size),
    do: String.to_existing_atom("#{pool_name}.#{:rand.uniform(pool_size)}")
end
