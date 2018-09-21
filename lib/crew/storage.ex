defmodule Crew.Storage do
  alias Crew.Job

  @timeout 30_000

  defmodule Message do
    defstruct job: nil, receipt: nil, id: nil
  end

  defmodule Adapter do
    alias Crew.Job

    @type server :: GenServer.server()
    @type queue :: String.t() | atom()

    @callback start_link(keyword()) :: {:ok, server()} | {:error, any()}
    @callback put_queue(server(), queue()) :: :ok | :error
    @callback put(server(), queue(), %Job{}) :: :ok | :error
    @callback get(server(), queue(), keyword()) :: {:ok, [%Message{}]} | {:error, any()}
    @callback update(server(), queue(), %Message{}) :: :ok | :error
    @callback delete(server(), queue(), %Message{}) :: :ok | :error
    @callback retire(server(), queue(), %Message{}) :: :ok | :error
  end

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    adapter = Keyword.fetch!(opts, :adapter)

    {:ok, %{adapter: adapter}}
  end

  def put_queue(storage, queue) do
    GenServer.call(storage, {:put_queue, queue})
  end

  def put(storage, queue, %Job{} = job) do
    GenServer.call(storage, {:put, queue, job})
  end

  def get(storage, queue, opts) do
    GenServer.call(storage, {:get, queue, opts}, @timeout)
  end

  def update(storage, queue, %Message{} = message) do
    GenServer.call(storage, {:update, queue, message})
  end

  def delete(storage, queue, %Message{} = message) do
    GenServer.call(storage, {:delete, queue, message})
  end

  def retire(storage, queue, %Message{} = message) do
    GenServer.call(storage, {:retire, queue, message})
  end

  def handle_call({:put_queue, queue}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.put_queue(conn, queue)
    {:reply, result, s}
  end

  def handle_call({:put, queue, job}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.put(conn, queue, job)
    {:reply, result, s}
  end

  def handle_call({:get, queue, opts}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.get(conn, queue, opts)
    {:reply, result, s}
  end

  def handle_call({:update, queue, message}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.update(conn, queue, message)
    {:reply, result, s}
  end

  def handle_call({:delete, queue, message}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.delete(conn, queue, message)
    {:reply, result, s}
  end

  def handle_call({:retire, queue, message}, _, %{adapter: {adapter, conn}} = s) do
    result = adapter.retire(conn, queue, message)
    {:reply, result, s}
  end
end
