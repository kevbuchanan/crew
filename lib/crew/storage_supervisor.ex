defmodule Crew.StorageSupervisor do
  use Supervisor

  alias Crew.Registry
  alias Crew.Storage

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    config = Keyword.fetch!(opts, :config)
    registry = Keyword.fetch!(opts, :registry)
    storage = Keyword.fetch!(opts, :storage)

    adapter_mod = Keyword.fetch!(opts, :adapter)
    adapter_name = Registry.name(registry, adapter_mod)
    adapter = {adapter_mod, adapter_name}

    opts =
      []
      |> Keyword.put(:config, config)
      |> Keyword.put(:registry, registry)
      |> Keyword.put(:adapter, adapter)
      |> Keyword.put(:storage, storage)

    children = [
      {adapter_mod, opts ++ [name: adapter_name]},
      {Storage, opts ++ [name: opts[:storage]]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
