defmodule Crew.WorkerPool do
  use DynamicSupervisor

  alias Crew.Worker

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def workers(supervisor) do
    supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(&elem(&1, 1))
  end

  def start_worker(supervisor, opts) do
    DynamicSupervisor.start_child(supervisor, {Worker, opts})
  end
end
