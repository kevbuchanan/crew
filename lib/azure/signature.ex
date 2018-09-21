defmodule Azure.Signature do
  # https://docs.microsoft.com/en-us/rest/api/storageservices/authentication-for-the-azure-storage-services#Subheading2
  def generate(%{method: method, path: path, body: body, headers: headers}, account, key) do
    content_length = if body == "", do: "", else: to_string(byte_size(body))

    string_to_sign =
      [
        String.upcase(Atom.to_string(method)),
        "",
        "",
        content_length,
        "",
        Keyword.get(headers, :"Content-Type", ""),
        "",
        "",
        "",
        "",
        "",
        "",
        canonicalized_headers(headers),
        canonicalized_resource(account, path)
      ]
      |> Enum.join("\n")

    :crypto.hmac(:sha256, Base.decode64!(key), string_to_sign)
    |> Base.encode64()
  end

  defp canonicalized_headers(headers) do
    [
      :"x-ms-blob-type",
      :"x-ms-date",
      :"x-ms-version"
    ]
    |> Enum.reduce([], fn header, parts ->
      case headers[header] do
        nil -> parts
        value -> parts ++ [Atom.to_string(header) <> ":" <> value]
      end
    end)
    |> Enum.join("\n")
  end

  defp canonicalized_resource(account, path) do
    uri = URI.parse(path)

    params =
      URI.query_decoder(uri.query || "")
      |> Enum.to_list()
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {k, v} -> "\n" <> k <> ":" <> v end)
      |> Enum.join()

    "/" <> account <> uri.path <> params
  end
end
