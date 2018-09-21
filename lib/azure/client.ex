defmodule Azure.Client do
  alias Azure.Signature
  alias Azure.Request
  alias Azure.Client.Queues

  @timeout 10_000

  defdelegate put_queue(name), to: Queues
  defdelegate get_queue_metadata(name), to: Queues
  defdelegate list_queues(), to: Queues
  defdelegate put_message(name, content, opts), to: Queues
  defdelegate get_messages(name, opts), to: Queues
  defdelegate update_message(name, message, content, opts), to: Queues
  defdelegate delete_message(name, message), to: Queues

  def perform(request, opts \\ [])

  def perform(%Request{service: :queue} = request, opts) do
    do_perform(request, config(:queue_service_endpoint), opts)
  end

  def do_perform(
        %Request{method: method, path: path, body: body, headers: headers} = req,
        endpoint,
        opts
      ) do
    url = Path.join(endpoint, path)

    date =
      Timex.now()
      |> Timex.format!("{RFC1123}")
      |> String.replace("+0000", "GMT")

    headers =
      headers ++
        [
          "x-ms-version": "2017-07-29",
          "x-ms-date": date
        ]

    signature =
      Signature.generate(
        %{method: method, path: path, body: body, headers: headers},
        config(:account),
        config(:key)
      )

    authorization = [
      {"Authorization", "SharedKey #{config(:account)}:#{signature}"}
    ]

    headers_with_auth = headers ++ authorization

    result =
      HTTPoison.request(
        method,
        url,
        body,
        headers_with_auth,
        hackney: opts,
        timeout: @timeout,
        recv_timeout: @timeout
      )

    Request.result(req, result)
  end

  defp config(key) do
    Application.get_env(:azure, key)
  end
end
