defmodule Crew.Worker.WorkProducer do
  use GenStage
  use Crew.Logger

  alias Crew.Storage

  @backoff 5_000

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)
    storage = Keyword.fetch!(opts, :storage)

    state = %{
      queue: queue,
      storage: storage,
      max_receive: Keyword.get(opts, :max_receive, 10),
      demand: 0,
      name: opts[:name],
      stopped: false
    }

    {:producer, state}
  end

  def stop(producer) do
    GenStage.cast(producer, :stop)
  end

  def handle_cast(:stop, state) do
    {:noreply, [], %{state | stopped: true}}
  end

  def handle_cast(:check_queue, %{stopped: true} = state) do
    {:noreply, [], state}
  end

  def handle_cast(:check_queue, %{demand: 0} = state) do
    {:noreply, [], state}
  end

  def handle_cast(:check_queue, %{demand: demand, max_receive: max_receive} = state) do
    case Storage.get(state.storage, state.queue, limit: min(demand, max_receive)) do
      {:ok, messages} ->
        GenStage.cast(state.name, :check_queue)

        {:noreply, messages, %{state | demand: demand - Enum.count(messages)}}

      {:error, reason} ->
        failed("Jobs.Fetch", reason, %{name: state.name})

        Process.send_after(self(), :backoff, @backoff)

        {:noreply, [], state}
    end
  end

  def handle_demand(more_demand, %{demand: demand} = state) do
    GenStage.cast(state.name, :check_queue)

    {:noreply, [], %{state | demand: demand + more_demand}}
  end

  def handle_info(:backoff, state) do
    GenStage.cast(state.name, :check_queue)

    {:noreply, [], state}
  end
end
