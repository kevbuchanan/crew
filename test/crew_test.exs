defmodule CrewTest do
  use ExUnit.Case

  alias Crew.WorkerPool

  import Crew.Support.Assertions

  defmodule TestWorker do
    use Crew.Handler
    use Crew.Scheduler

    job(TestJob, numbers: nil)

    def perform(%TestJob{numbers: numbers}) do
      {:ok, numbers}
    end

    def next_three_times do
      ~e[0 */3 * * * *] |> next(3)
    end
  end

  setup do
    start_supervised({Crew, [adapter: Crew.Storage.Test]})
    :ok
  end

  describe "schedule/2" do
    test "schedules a job" do
      :ok = Crew.schedule(%TestWorker.TestJob{numbers: [1, 2, 3]}, at: DateTime.utc_now())

      assert Crew.Storage.Test.scheduled_jobs() == [
        %TestWorker.TestJob{numbers: [1, 2, 3]}
      ]
    end

    test "schedules jobs at multiple times" do
      times = TestWorker.next_three_times()
      :ok = Crew.schedule(%TestWorker.TestJob{numbers: [1, 2, 3]}, at: times)

      assert Crew.Storage.Test.scheduled_jobs() == [
        %TestWorker.TestJob{numbers: [1, 2, 3]},
        %TestWorker.TestJob{numbers: [1, 2, 3]},
        %TestWorker.TestJob{numbers: [1, 2, 3]}
      ]
    end
  end

  describe "subscribe/1" do
    test "starts a new worker" do
      :ok = Crew.subscribe("queue-a")

      assert_eventually(fn -> WorkerPool.workers(WorkerPool) |> Enum.count() == 1 end)
    end

    test "returns existing worker" do
      :ok = Crew.subscribe("queue-a")
      :ok = Crew.subscribe("queue-a")

      assert_eventually(fn -> WorkerPool.workers(WorkerPool) |> Enum.count() == 1 end)
    end
  end
end
