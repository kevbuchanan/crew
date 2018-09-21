defmodule Crew.JobTest do
  use ExUnit.Case

  alias Crew.Job

  defmodule TestWorker do
    use Crew.Handler
    use Crew.Scheduler

    job(TestJob, numbers: nil)

    def perform(%TestJob{numbers: numbers}) do
      {:ok, numbers}
    end
  end

  describe "Job.new/1" do
    test "builds the job name" do
      job = Job.new(%TestWorker.TestJob{numbers: [1, 2, 3]})

      assert job.name == "Crew.JobTest.TestWorker.TestJob"
    end

    test "includes the job data" do
      job = Job.new(%TestWorker.TestJob{numbers: [1, 2, 3]})

      assert job.data == %TestWorker.TestJob{numbers: [1, 2, 3]}
    end
  end

  describe "Job.execute/1" do
    test "performs the job" do
      job = Job.new(%TestWorker.TestJob{numbers: [4, 5, 6]})
      result = Job.execute(job)

      assert result == :ok
    end
  end
end
