defmodule Crew.Job do
  defstruct name: nil, data: nil, perform_at: nil, tries: 0

  alias __MODULE__

  def new(work, opts \\ []) do
    name = work.__struct__
           |> Atom.to_string()
           |> String.replace_prefix("Elixir.", "")

    %__MODULE__{
      name: name,
      data: work,
      perform_at: opts[:at]
    }
  end

  def execute(%__MODULE__{} = job) do
    work = to_work(job)
    apply(work.__struct__, :perform, [work])
    :ok
  end

  def to_work(%__MODULE__{name: name, data: data}) do
    module = String.to_existing_atom("Elixir.#{name}")
    work = struct(module)
    work
    |> Map.to_list()
    |> Enum.reduce(work, fn {k, _}, acc ->
      case Map.fetch(data, k) do
        {:ok, v} ->
          %{acc | k => v}

        :error ->
          case Map.fetch(data, Atom.to_string(k)) do
            {:ok, v} -> %{acc | k => v}
            :error -> acc
          end
      end
    end)
  end

  def retry(job) do
    Map.put(job, :tries, job.tries + 1)
  end

  def backoff(%Job{tries: tries} = job) do
    Map.put(job, :perform_at, retry_at(tries))
  end

  defp retry_at(tries) do
    Timex.shift(Timex.now(), seconds: backoff_seconds(tries))
  end

  # https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry
  defp backoff_seconds(tries) do
    round(:math.pow(tries, 4)) + 15 + :rand.uniform(30) * (tries + 1)
  end
end
