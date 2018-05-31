defmodule RedisZ.PoolStarter do
  @moduledoc """
  """

  use Task, restart: :transient

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(args), do: Task.start_link(__MODULE__, :run, [args])

  @spec run(keyword) :: any
  def run(args) do
    if is_nil(Process.whereis(args[:pool_name])) do
      Process.sleep(10)
      run(args)
    else
      for i <- 1..args[:pool_size] do
        spec = Supervisor.Spec.worker(Redix, [args[:url], [name: :"#{args[:pool_name]}.#{i}"]])
        {:ok, _} = DynamicSupervisor.start_child(args[:pool_name], spec)
      end
    end
  end
end
