defmodule RedisZ.ShardsStarter do
  @moduledoc """
  Start `RedisZ.Shard` workers under `RedisZ.Shards`.
  """

  alias RedisZ.Shard

  use Task, restart: :transient

  @doc false
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(args), do: Task.start_link(__MODULE__, :run, [args])

  @spec run(keyword) :: any
  def run(args) do
    if is_nil(Process.whereis(args[:shards_name])) do
      Process.sleep(10)
      run(args)
    else
      for {url, i} <- Enum.with_index(args[:urls], 1) do
        args =
          args
          |> Keyword.delete(:urls)
          |> put_in([:url], url)
          |> put_in([:name], :"#{args[:shards_name]}.#{i}")

        {:ok, _} = DynamicSupervisor.start_child(args[:shards_name], {Shard, args})
      end
    end
  end
end
