defmodule Crew do
  use Supervisor

  alias Crew.{
    Job,
    StorageSupervisor,
    Storage,
    Registry,
    WorkerSupervisor,
    WorkerManager,
    WorkerPool,
  }

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    queues = Keyword.get(opts, :queues, [])
    drain = Keyword.get(opts, :drain, false)
    work = Keyword.get(opts, :work, true)

    config = [
      queues: queues,
      drain: drain
    ]

    opts =
      []
      |> Keyword.put(:config, config)
      |> Keyword.put(:adapter, adapter)
      |> Keyword.put(:work, work)
      |> Keyword.put(:registry, Registry)
      |> Keyword.put(:storage_supervisor, StorageSupervisor)
      |> Keyword.put(:storage, Storage)
      |> Keyword.put(:worker_supervisor, WorkerSupervisor)
      |> Keyword.put(:worker_pool, WorkerPool)
      |> Keyword.put(:worker_manager, WorkerManager)

    children = [
      {Registry, opts ++ [name: opts[:registry]]},
      {StorageSupervisor, opts ++ [name: opts[:storage_supervisor]]},
      {WorkerSupervisor, opts ++ [name: opts[:worker_supervisor]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def subscribe(queue) do
    WorkerManager.start_worker(WorkerManager, queue)
  end

  def unsubscribe_all do
    WorkerManager.stop_workers(WorkerManager)
  end

  def schedule(job) do
    schedule("default", job, [])
  end

  def schedule(job, opts) do
    schedule("default", job, opts)
  end

  def schedule(queue, job, at: times) when is_list(times) do
    times
    |> Enum.map(fn t -> schedule(queue, job, at: t) end)
    |> combine_results()
  end

  def schedule(queue, job, opts) do
    job = Job.new(job, opts)

    Storage.put(Storage, queue, job)
  end

  defp combine_results(results) do
    Enum.reduce(results, :ok, fn
      :ok, :ok -> :ok
      _, {:error, _} = e -> e
      {:error, _} = e, _ -> e
    end)
  end
end
