defmodule RedisZ.Diagnoser do
  @moduledoc """
  Auto reconnect at Amazon ElastiCache Multi-AZ failover.
  """

  use GenServer

  @type t :: %{
          name: atom,
          recovering: %{atom => [GenServer.from()]}
        }

  @elasticache_readonly_error "READONLY You can't write against a read only slave."
  @reconnect_interval 100
  @reconnect_times Integer.floor_div(5000, @reconnect_interval) - 1

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: args[:diagnoser_name])

  @spec init(keyword) :: {:ok, t}
  def init(args), do: {:ok, %{name: args[:diagnoser_name], recovering: %{}}}

  @doc """
  """
  @spec diagnose(atom, atom, Exception.t() | :noproc) :: :recovered | :error
  def diagnose(diagnoser, redix_conn, error),
    do: GenServer.call(diagnoser, {:diagnose, redix_conn, error})

  @spec handle_call({:diagnose, atom, Exception.t() | :noproc}, GenServer.from(), t) ::
          {:noreply, t} | {:reply, :error, t}
  def handle_call({:diagnose, redix_conn, :noproc}, from, state) do
    if Map.has_key?(state.recovering, redix_conn) do
      {:noreply, update_in(state.recovering[redix_conn], &[from | &1])}
    else
      {:reply, :error, state}
    end
  end

  def handle_call({:diagnose, redix_conn, error}, from, state) do
    if error[:message] == @elasticache_readonly_error do
      unless Map.has_key?(state.recovering, redix_conn) do
        Task.start(fn ->
          Redix.stop(redix_conn)
          wait_for_reconnecting(redix_conn, state.name)
        end)
      end

      state = update_in(state.recovering[redix_conn], &[from | &1 || []])

      {:noreply, state}
    else
      {:reply, :error, state}
    end
  end

  @spec handle_cast({:recover_result, atom, :recovered | :error}, t) :: {:noreply, t}
  def handle_cast({:recover_result, redix_conn, response}, state) do
    {from_processes, state} = pop_in(state.recovering[redix_conn])
    Enum.each(from_processes, &GenServer.reply(&1, response))
    {:noreply, state}
  end

  @spec wait_for_reconnecting(atom, atom, non_neg_integer) :: :ok
  defp wait_for_reconnecting(redix_conn, diagnoser, times \\ 0) do
    if times > @reconnect_times do
      GenServer.cast(diagnoser, {:recover_result, redix_conn, :error})
    else
      Process.sleep(@reconnect_interval)

      if is_nil(GenServer.whereis(redix_conn)) do
        wait_for_reconnecting(redix_conn, diagnoser, times + 1)
      else
        GenServer.cast(diagnoser, {:recover_result, redix_conn, :recovered})
      end
    end
  end
end
