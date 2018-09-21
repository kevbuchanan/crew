defmodule Crew.Storage.Agent do
  @behaviour Crew.Storage.Adapter

  use Agent

  alias Crew.Storage.Message

  def start_link(opts) do
    Agent.start_link(fn -> %{} end, name: opts[:name])
  end

  def queue(agent, name) do
    Agent.get(agent, fn queues -> Map.get(queues, name, []) end)
  end

  def put_queue(_agent, _queue) do
    :ok
  end

  def put(agent, queue, job) do
    Agent.update(agent, fn queues ->
      Map.update(queues, queue, [job], fn jobs -> jobs ++ job end)
    end)

    :ok
  end

  def get(agent, queue, _) do
    jobs = Agent.get(agent, fn queues -> Map.get(queues, queue, []) end)

    messages =
      Enum.map(jobs, fn j ->
        %Message{id: nil, job: j, receipt: nil}
      end)

    {:ok, messages}
  end

  def update(_s, _q, _message) do
    :ok
  end

  def delete(agent, queue, message) do
    Agent.update(agent, fn queues ->
      Map.update(queues, queue, [], fn jobs -> List.delete(jobs, message.job) end)
    end)

    :ok
  end

  def retire(_s, _q, _message) do
    :ok
  end
end
