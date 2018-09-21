defmodule Crew.Registry do
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    Registry.start_link(keys: :unique, name: opts[:name])
  end

  def name(registry, term) do
    {:via, Registry, {registry, term}}
  end

  def worker(registry, queue_name) do
    %{
      name: name(registry, {:worker, queue_name}),
      consumer: worker_consumer(registry, queue_name),
      producer: worker_producer(registry, queue_name)
    }
  end

  defp worker_consumer(registry, queue_name) do
    %{
      name: name(registry, {:worker_consumer, queue_name})
    }
  end

  defp worker_producer(registry, queue_name) do
    %{
      name: name(registry, {:worker_producer, queue_name})
    }
  end

  def lookup(registry, {:via, Registry, {registry, key}}) do
    case Registry.lookup(registry, key) do
      [] -> nil
      [{pid, _}] -> pid
    end
  end
end
