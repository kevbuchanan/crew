defmodule Crew.Worker.WorkConsumer do
  use ConsumerSupervisor

  alias Crew.Worker.WorkExecutor

  @timeout 20_000
  @max_demand 20

  def start_link(opts) do
    ConsumerSupervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)
    storage = Keyword.fetch!(opts, :storage)
    producer = Keyword.fetch!(opts, :producer)
    max_tries = Keyword.fetch!(opts, :max_tries)
    max_demand = Keyword.get(opts, :max_demand, @max_demand)

    opts = [
      queue: queue,
      max_tries: max_tries,
      storage: storage
    ]

    children = [
      %{
        id: WorkExecutor,
        start: {WorkExecutor, :start_link, [opts]},
        restart: :temporary,
        shutdown: @timeout
      }
    ]

    ConsumerSupervisor.init(
      children,
      strategy: :one_for_one,
      subscribe_to: [{producer.name, [max_demand: max_demand]}]
    )
  end
end
