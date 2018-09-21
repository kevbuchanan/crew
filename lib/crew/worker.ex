defmodule Crew.Worker do
  use Supervisor

  alias Crew.Worker.{
    WorkProducer,
    WorkConsumer
  }

  alias Crew.Storage

  defmodule PutQueue do
    use Task

    def start_link(opts) do
      Task.start_link(__MODULE__, :run, [opts])
    end

    def run(opts) do
      queue = Keyword.fetch!(opts, :queue)
      storage = Keyword.fetch!(opts, :storage)

      :ok = Storage.put_queue(storage, queue)
    end
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)
    storage = Keyword.fetch!(opts, :storage)
    producer = Keyword.fetch!(opts, :producer)
    consumer = Keyword.fetch!(opts, :consumer)
    max_tries = Keyword.fetch!(opts, :max_tries)

    opts = [
      queue: queue,
      max_tries: max_tries,
      storage: storage,
      producer: producer,
      consumer: consumer
    ]

    children = [
      {PutQueue, opts},
      {WorkProducer, opts ++ [name: producer.name]},
      {WorkConsumer, opts ++ [name: consumer.name]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
