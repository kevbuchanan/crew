defmodule Crew.Scheduler do
  alias Crontab.{
    CronExpression,
    Scheduler
  }

  defmacro __using__(opts \\ []) do
    queue = Keyword.get(opts, :queue, "default")

    quote do
      import Crontab.CronExpression
      import Timex, except: [after?: 2]
      import unquote(__MODULE__)

      def schedule(job, opts \\ []) do
        Crew.schedule(unquote(queue), job, opts)
      end
    end
  end

  def next(%CronExpression{} = expression, n_runs \\ 1) do
    expression
    |> Scheduler.get_next_run_dates()
    |> Enum.take(n_runs)
    |> Enum.map(&DateTime.from_naive!(&1, "Etc/UTC"))
  end

  def next_occurrence(%Time{} = time) do
    if after?(Time.utc_now(), time) do
      Timex.now()
      |> Timex.shift(days: 1)
      |> at_time(time)
    else
      Timex.now()
      |> at_time(time)
    end
  end

  @doc "Returns a boolean indicating whether the first time occurs after the second"
  def after?(t1, t2) do
    case Timex.compare(t1, t2, :minutes) do
      -1 -> false
      0 -> true
      1 -> true
    end
  end

  def at_time(%DateTime{} = dt, %Time{} = time) do
    Timex.set(
      dt,
      hour: time.hour,
      minute: time.minute,
      second: time.second,
      microsecond: {0, 6}
    )
  end
end
