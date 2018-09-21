defmodule Azure.Client.Queues do
  import Azure.Request
  import SweetXml
  import XmlBuilder

  def put_queue(name) do
    new(:queue)
    |> method(:put)
    |> path("/#{name}")
    |> header("Content-Type": "application/xml")
    |> handle(fn
      {:ok, %{status_code: code}} when code in [201, 204] ->
        {:ok, %{name: name}}

      _e ->
        {:error, "unable to put queue"}
    end)
  end

  def get_queue_metadata(name) do
    new(:queue)
    |> method(:get)
    |> path("/#{name}?comp=metadata")
    |> handle(fn
      {:ok, %{status_code: 200} = resp} ->
        message_count =
          resp.headers
          |> Enum.into(%{})
          |> Map.get("x-ms-approximate-messages-count")
          |> String.to_integer()

        %{
          message_count: message_count
        }

      e ->
        {:error, e}
    end)
  end

  def list_queues do
    new(:queue)
    |> method(:get)
    |> path("/?comp=list")
    |> handle(fn
      {:ok, %{status_code: 200, body: body}} ->
        xpath(body, ~x"//Queue"l, name: ~x"./Name/text()"s)

      e ->
        {:error, e}
    end)
  end

  def put_message(queue_name, content, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 0)

    new(:queue)
    |> method(:post)
    |> path("/#{queue_name}/messages?visibilitytimeout=#{timeout}&messagettl=-1")
    |> header("Content-Type": "application/xml")
    |> body(
      generate(
        element(:QueueMessage, [
          element(:MessageText, content)
        ])
      )
    )
    |> handle(fn
      {:ok, %{status_code: 201}} ->
        :ok

      _e ->
        :error
    end)
  end

  def get_messages(queue_name, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 20)
    limit = Keyword.get(opts, :limit, 1)

    new(:queue)
    |> method(:get)
    |> path("/#{queue_name}/messages?numofmessages=#{limit}&visibilitytimeout=#{timeout}")
    |> handle(fn
      {:ok, %{body: body, status_code: 200}} ->
        messages =
          body
          |> xmap(
            messages: [
              ~x"//QueueMessagesList/QueueMessage"l,
              id: ~x"./MessageId/text()"s,
              receipt: ~x"./PopReceipt/text()"s,
              content: ~x"./MessageText/text()"s
            ]
          )
          |> Map.get(:messages)

        {:ok, messages}

      _e ->
        {:error, "failed to get messages"}
    end)
  end

  def update_message(queue_name, message, content, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 0)

    query =
      URI.encode_query(%{
        "popreceipt" => message.receipt,
        "visibilitytimeout" => timeout,
        "messagettl" => -1
      })

    new(:queue)
    |> method(:put)
    |> path("/#{queue_name}/messages/#{message.id}?#{query}")
    |> header("Content-Type": "application/xml")
    |> body(
      generate(
        element(:QueueMessage, [
          element(:MessageText, content)
        ])
      )
    )
    |> handle(fn
      {:ok, %{status_code: 204}} ->
        :ok

      _e ->
        :error
    end)
  end

  def delete_message(queue_name, message) do
    query = URI.encode_query(%{"popreceipt" => message.receipt})

    new(:queue)
    |> method(:delete)
    |> path("/#{queue_name}/messages/#{message.id}?#{query}")
    |> handle(fn
      {:ok, %{status_code: 204}} ->
        :ok

      _e ->
        :error
    end)
  end
end
