defmodule Crew.WorkerManager do
  @shutdown_delay 10_000

  use GenServer, shutdown: @shutdown_delay + 10

  alias Crew.Registry
  alias Crew.WorkerPool
  alias Crew.Worker.WorkProducer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    Process.flag(:trap_exit, true)

    config = Keyword.get(opts, :config, [])

    pool = Keyword.fetch!(opts, :worker_pool)
    registry = Keyword.fetch!(opts, :registry)
    storage = Keyword.fetch!(opts, :storage)
    max_tries = Keyword.fetch!(opts, :max_tries)
    drain = Keyword.get(config, :drain, false)

    state = %{
      pool: pool,
      registry: registry,
      storage: storage,
      max_tries: max_tries,
      queues: [],
      drain: drain
    }

    {:ok, state}
  end

  def start_worker(manager, queue) do
    GenServer.cast(manager, {:start_worker, queue})
  end

  def stop_workers(manager) do
    GenServer.cast(manager, :stop_workers)
  end

  def handle_cast({:start_worker, queue}, state) do
    worker = Registry.worker(state.registry, queue)

    queues =
      case Registry.lookup(state.registry, worker.name) do
        nil ->
          opts = [
            name: worker.name,
            producer: worker.producer,
            consumer: worker.consumer,
            queue: queue,
            storage: state.storage,
            max_tries: state.max_tries
          ]

          WorkerPool.start_worker(state.pool, opts)

          [queue | state.queues]

        _pid ->
          state.queues
      end

    {:noreply, %{state | queues: queues}}
  end

  def handle_cast(:stop_workers, state) do
    stop_work_producers(state)

    {:noreply, state}
  end

  def terminate(:normal, state), do: drain_work(state)
  def terminate(:shutdown, state), do: drain_work(state)
  def terminate({:shutdown, _}, state), do: drain_work(state)
  def terminate(_, _state), do: :ok

  defp stop_work_producers(state) do
    for queue <- state.queues do
      worker = Registry.worker(state.registry, queue)
      WorkProducer.stop(worker.producer.name)
    end
  end

  defp drain_work(%{queues: []}) do
    :ok
  end

  defp drain_work(%{drain: true} = state) do
    delay = @shutdown_delay
    Logger.info("WorkerManager received shutdown. Stopping work. Delaying shutdown for #{delay} ms...")
    stop_work_producers(state)
    :timer.sleep(delay)
    :ok
  end

  defp drain_work(%{drain: false} = state) do
    stop_work_producers(state)
    :ok
  end
end
