defmodule Azure.Request do
  defstruct method: nil,
            path: nil,
            body: "",
            headers: [],
            service: nil,
            handler: nil

  def new(service) do
    %__MODULE__{service: service, handler: fn r -> r end}
  end

  def method(req, method) do
    Map.put(req, :method, method)
  end

  def path(req, path) do
    Map.put(req, :path, path)
  end

  def handle(req, handler) do
    Map.put(req, :handler, handler)
  end

  def result(req, result) do
    req.handler.(result)
  end

  def body(req, body) do
    Map.put(req, :body, body)
  end

  def header(req, header) do
    Map.put(req, :headers, req.headers ++ header)
  end
end
