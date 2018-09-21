defmodule Crew.Storage.Test do
  @behaviour Crew.Storage.Adapter

  use Agent

  def start_link(_opts) do
    case Process.whereis(__MODULE__) do
      nil -> Agent.start_link(fn -> [] end, name: __MODULE__)
      pid -> {:ok, pid}
    end
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> [] end)
  end

  def scheduled_jobs do
    Agent.get(__MODULE__, fn jobs ->
      Enum.map(jobs, fn j -> j.data end)
    end)
  end

  def put_queue(_, _q) do
    :ok
  end

  def put(_, _q, job) do
    Agent.update(__MODULE__, fn jobs -> jobs ++ [job] end)
  end

  def get(_s, _q, _) do
    {:ok, []}
  end

  def update(_s, _q, _message) do
    :ok
  end

  def delete(_s, _q, _message) do
    :ok
  end

  def retire(_s, _q, _message) do
    :ok
  end
end
