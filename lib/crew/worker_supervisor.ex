defmodule Crew.WorkerSupervisor do
  use Supervisor

  alias Crew.{
    WorkerPool,
    WorkerManager
  }

  defmodule StartWorkers do
    use Task

    def start_link(opts) do
      Task.start_link(__MODULE__, :run, [opts])
    end

    def run(opts) do
      work = Keyword.get(opts, :work, true)
      queues = Keyword.get(opts, :queues, [])
      manager = Keyword.fetch!(opts, :worker_manager)

      if work do
        for queue <- queues do
          :ok = WorkerManager.start_worker(manager, queue)
        end
      end
    end
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    config = Keyword.fetch!(opts, :config)
    work = Keyword.get(opts, :work, true)
    queues = Keyword.get(config, :queues, [])
    max_tries = Keyword.get(config, :max_tries, 1)
    registry = Keyword.fetch!(opts, :registry)
    storage = Keyword.fetch!(opts, :storage)
    worker_pool = Keyword.fetch!(opts, :worker_pool)
    worker_manager = Keyword.fetch!(opts, :worker_manager)

    opts = [
      work: work,
      queues: queues,
      max_tries: max_tries,
      registry: registry,
      storage: storage,
      worker_pool: worker_pool,
      worker_manager: worker_manager
    ]

    children = [
      {WorkerPool, opts ++ [name: opts[:worker_pool]]},
      {WorkerManager, opts ++ [name: opts[:worker_manager]]},
      {StartWorkers, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
