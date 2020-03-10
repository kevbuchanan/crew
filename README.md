# Crew

### Job processing with pluggable backends.

Crew is designed to process jobs from "smart" queueing backends (i.e. AWS SQS,
Azure Queue Storage). The backend is responsible for guaranteeing integrity of
the job queue. Crew simply provides the interface for backends and processes
jobs from the configured queues. Crew dispatches retry and retire events for jobs.

## Usage

```elixir
config :crew,
  adapter: Crew.Storage.Azure,
  max_tries: 5,
  queues: [
    "default",
    "queue_a",
    "queue_b",
    "queue_c"
  ]

config :azure,
  key: "${AZURE_STORAGE_KEY}",
  account: "${AZURE_STORAGE_ACCOUNT}",
  queue_service_endpoint: "${AZURE_QUEUE_ENDPOINT}"
```

```elixir
Crew.start_link(Application.get_env(:crew))

defmodule MyWork do
  use Crew.Handler
  use Crew.Scheduler

  job(SendReminder, message: nil)
  job(SendEmail, user_id: nil)

  def perform(%SendReminder{message: message}) do
    IO.puts(message)
  end

  def perform(%SendEmail{user_id: user_id}) do
    :ok = Email.send(user_id)
  end

  def next_three_times do
    ~e[0 */3 * * * *] |> next(3)
  end
end

:ok = Crew.schedule(%MyWork.SendReminder{message: "Do it!"}, at: MyWork.next_three_times())
:ok = Crew.schedule(%MyWork.SendEmail{user_id: user_id})
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `crew` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crew, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/crew](https://hexdocs.pm/crew).

