defmodule RedisZ.PoolStarter do
  @moduledoc """
  Start `Redix` workers under `RedisZ.Pool`.
  """

  use Task, restart: :transient

  @doc false
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(args), do: Task.start_link(__MODULE__, :run, [args])

  @spec run(keyword) :: any
  def run(args) do
    if is_nil(Process.whereis(args[:pool_name])) do
      Process.sleep(10)
      run(args)
    else
      for i <- 1..args[:pool_size] do
        spec = %{
          id: Redix,
          start: {Redix, :start_link, [args[:url], [name: :"#{args[:pool_name]}.#{i}"]]}
        }

        case DynamicSupervisor.start_child(args[:pool_name], spec) do
          {:ok, _} ->
            nil

          {:ok, _, _} ->
            nil

          {:error, {error, stacktrace}} when is_map(error) and is_list(stacktrace) ->
            reraise error, stacktrace

          reason ->
            raise reason
        end
      end
    end
  end
end
