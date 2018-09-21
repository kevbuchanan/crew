defmodule Crew.Storage.Azure do
  @behaviour Crew.Storage.Adapter

  use Supervisor

  alias Crew.Job
  alias Crew.Storage.Message
  alias Azure.Connection

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    pool = Keyword.get(opts, :pool, __MODULE__)
    name = Keyword.fetch!(opts, :name)

    opts = [
      name: name,
      pool: pool
    ]

    children = [
      :hackney_pool.child_spec(pool, timeout: 15_000, max_connections: 20),
      {Connection, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def put_queue(conn, queue) do
    queue = sanitize(queue)

    conn
    |> Connection.exec(:put_queue, [queue])
    |> case do
      {:ok, _} -> :ok
      _e -> :error
    end
  end

  def put(conn, queue, %Job{perform_at: perform_at} = job) when not is_nil(perform_at) do
    queue = sanitize(queue)
    job = Poison.encode!(job)

    timeout =
      perform_at
      |> Timex.diff(Timex.now(), :seconds)
      |> max(0)

    Connection.exec(conn, :put_message, [queue, job, [timeout: timeout]])
  end

  def put(conn, queue, job) do
    queue = sanitize(queue)
    job = Poison.encode!(job)

    Connection.exec(conn, :put_message, [queue, job, []])
  end

  def get(conn, queue, opts) do
    queue = sanitize(queue)
    limit = Keyword.get(opts, :limit, 1)

    conn
    |> Connection.exec(:get_messages, [queue, [limit: limit]])
    |> case do
      {:ok, m} -> {:ok, Enum.map(m, &parse_message/1)}
      e -> e
    end
  end

  def update(conn, queue, message) do
    queue = sanitize(queue)

    timeout =
      message.job.perform_at
      |> Timex.diff(Timex.now(), :seconds)
      |> max(0)

    job = Poison.encode!(message.job)

    Connection.exec(conn, :update_message, [queue, message, job, [timeout: timeout]])
  end

  def delete(conn, queue, message) do
    queue = sanitize(queue)

    Connection.exec(conn, :delete_message, [queue, message])
  end

  def retire(conn, queue, message) do
    queue = sanitize(queue)

    Connection.exec(conn, :delete_message, [queue, message])
  end

  defp sanitize(queue) do
    String.replace(queue, ":", "-")
  end

  defp parse_message(message) do
    content = Poison.decode!(message.content)

    %Message{
      id: message.id,
      receipt: message.receipt,
      job: %Job{
        name: content["name"],
        data: content["data"],
        perform_at: parse_perform_at(content["perform_at"]),
        tries: content["tries"]
      }
    }
  end

  defp parse_perform_at(nil), do: nil

  defp parse_perform_at(perform_at) do
    case DateTime.from_iso8601(perform_at) do
      {:ok, perform_at, _} -> perform_at
      {:error, _} -> nil
    end
  end
end
