defmodule RedisZ.Server do
  @moduledoc """
  Manage ETS which lists `RedisZ.Shard` workers.
  """

  use GenServer

  @type name :: GenServer.server()

  @type t :: %{store: :ets.tab()}

  @doc false
  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: args[:server_name])

  @doc false
  @spec init(keyword) :: {:ok, t}
  def init(args) do
    tab = :ets.new(args[:server_name], [:named_table, read_concurrency: true])
    args = put_in(args[:shards], [])
    true = :ets.insert_new(tab, args)
    {:ok, %{store: tab}}
  end

  @spec handle_cast({:add_shard, keyword}, t) :: {:noreply, t}
  def handle_cast({:add_shard, shard}, %{store: store} = state) do
    :ets.insert(store, {:shards, [shard | :ets.lookup_element(store, :shards, 2)]})
    {:noreply, state}
  end
end
