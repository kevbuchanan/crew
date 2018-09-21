defmodule Crew.Worker.WorkExecutor do
  use GenServer
  use Crew.Logger

  alias Crew.Job
  alias Crew.Storage

  def start_link(opts, message) do
    GenServer.start_link(__MODULE__, {opts, message})
  end

  def init({opts, message}) do
    queue = Keyword.fetch!(opts, :queue)
    storage = Keyword.fetch!(opts, :storage)
    max_tries = Keyword.fetch!(opts, :max_tries)

    state = %{
      queue: queue,
      storage: storage,
      max_tries: max_tries,
      message: message
    }

    {:ok, state, 0}
  end

  def handle_info(:timeout, state) do
    execute(state.storage, state.queue, state.message, state.max_tries)

    {:stop, :normal, state}
  end

  def execute(storage, queue, %Storage.Message{job: job} = message, max_tries) do
    instrument "Job.Execute", %{job: job} do
      :ok = Job.execute(job)
      :ok = Storage.delete(storage, queue, message)
    end
  rescue
    _ ->
      retry(storage, queue, message, max_tries)
  end

  defp retry(storage, queue, %Storage.Message{job: job} = message, max_tries) do
    retry_job =
      job
      |> Job.retry()
      |> Job.backoff()

    retry_message = Map.put(message, :job, retry_job)
    do_retry(storage, queue, retry_message, max_tries)
  end

  defp do_retry(storage, queue, %Storage.Message{job: %Job{tries: tries}} = message, max_retries)
       when tries >= max_retries do
    Storage.retire(storage, queue, message)
  end

  defp do_retry(storage, queue, message, _) do
    Storage.update(storage, queue, message)
  end
end
