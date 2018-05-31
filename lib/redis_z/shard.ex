defmodule RedisZ.Shard do
  @moduledoc """
  Parallel connection pooling.
  """

  alias RedisZ.{Diagnoser, Pool, PoolStarter}

  use Supervisor

  @spec start_link(keyword) :: Supervisor.on_start()
  def start_link(args), do: Supervisor.start_link(__MODULE__, args)

  @spec init(keyword) :: {:ok, {:supervisor.sup_flags(), [:supervisor.child_spec()]}} | :ignore
  def init(args) do
    args = put_in(args[:pool_name], :"#{args[:name]}.Pool")

    children = [
      {Pool, args},
      {PoolStarter, args}
    ]

    GenServer.cast(args[:server_name], {:add_shard, args})
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  """
  @spec pipeline(atom, [Redix.command()], keyword) ::
          {:ok, [Redix.Protocol.redis_value()]} | {:error, atom | Redix.Error.t()}
  def pipeline(conn, commands, opts \\ []), do: do_apply(:pipeline, conn, commands, opts)

  @doc """
  """
  @spec pipeline!(atom, [Redix.command()], keyword) :: [Redix.Protocol.redis_value()] | no_return
  def pipeline!(conn, commands, opts \\ []), do: do_apply(:pipeline!, conn, commands, opts)

  @doc """
  """
  @spec command(atom, Redix.command(), keyword) ::
          {:ok, Redix.Protocol.redis_value()} | {:error, atom | Redix.Error.t()}
  def command(conn, command, opts \\ []), do: do_apply(:command, conn, command, opts)

  @doc """
  """
  @spec command!(atom, Redix.command(), keyword) :: Redix.Protocol.redis_value() | no_return
  def command!(conn, command, opts \\ []), do: do_apply(:command!, conn, command, opts)

  @spec do_apply(atom, atom, [Redix.command()], keyword) :: term
  defp do_apply(fun_name, conn, commands, opts) do
    server_name = conn |> Module.split() |> Enum.slice(0..-3) |> Module.concat()
    args = Enum.find(:ets.tab2list(server_name)[:shards], &(&1[:name] === conn))
    redix_conn = Pool.get_conn(args[:pool_name], args[:pool_size])
    opts = put_in(opts[:diagnoser_name], args[:diagnoser_name])
    do_apply_with_retry(fun_name, redix_conn, commands, opts)
  end

  @spec do_apply_with_retry(atom, atom, [Redix.command()], keyword) :: term
  defp do_apply_with_retry(fun_name, redix_conn, commands, opts)
       when fun_name in [:pipeline, :command] do
    with {:error, error} <- apply(Redix, fun_name, [redix_conn, commands, opts]),
         :error <- Diagnoser.diagnose(opts[:diagnoser_name], redix_conn, error) do
      {:error, error}
    else
      {:ok, result} -> {:ok, result}
      :recovered -> do_apply_with_retry(redix_conn, fun_name, commands, opts)
    end
  catch
    :exit, {:noproc, _} ->
      case Diagnoser.diagnose(opts[:diagnoser_name], redix_conn, :noproc) do
        :recovered -> do_apply_with_retry(redix_conn, fun_name, commands, opts)
        :error -> {:error, Redix.Error.exception(message: "Can't connect to redis master")}
      end
  end

  defp do_apply_with_retry(fun_name, redix_conn, commands, opts)
       when fun_name in [:pipeline!, :command!] do
    apply(Redix, fun_name, [redix_conn, commands, opts])
  rescue
    error ->
      stacktrace = System.stacktrace()

      case Diagnoser.diagnose(opts[:diagnoser_name], redix_conn, error) do
        :recovered -> do_apply_with_retry(redix_conn, fun_name, commands, opts)
        :error -> reraise error, stacktrace
      end
  catch
    :exit, {:noproc, _} ->
      case Diagnoser.diagnose(opts[:diagnoser_name], redix_conn, :noproc) do
        :recovered -> do_apply_with_retry(redix_conn, fun_name, commands, opts)
        :error -> raise Redix.Error, message: "Can't connect to redis master"
      end
  end
end
