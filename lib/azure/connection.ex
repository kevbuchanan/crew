defmodule Azure.Connection do
  use GenServer

  alias Azure.Client

  @timeout 30_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    pool = Keyword.fetch!(opts, :pool)

    {:ok, %{pool: pool}}
  end

  def exec(conn, action, args) do
    GenServer.call(conn, {:exec, {action, args}}, @timeout)
  end

  def handle_call({:exec, {action, args}}, _, state) do
    result =
      apply(Client, action, args)
      |> Client.perform(pool: state.pool)

    {:reply, result, state}
  end
end
