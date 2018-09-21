defmodule Crew.Logger.Instrument do
  alias Timex.Duration

  defmacro instrument(event, properties, do: body) do
    quote do
      event_name = unquote(event)
      properties = unquote(properties)

      start = Duration.now()

      try do
        result = unquote(body)

        duration = Duration.diff(Duration.now(), start)

        Logger.info(
          "#{event_name} complete - #{inspect(properties)}",
          event: %{
            name: "#{event_name}.Complete",
            properties: properties,
            measurements: %{
              durationMs: Duration.to_milliseconds(duration, truncate: true)
            }
          }
        )

        result
      rescue
        e ->
          stacktrace = System.stacktrace()
          message = Exception.message(e)

          Logger.info(
            "#{event_name} failed - #{message} - #{inspect(properties)}",
            event: %{
              name: "#{event_name}.Failed",
              properties:
                Map.merge(properties, %{
                  error: message,
                  stacktrace: Exception.format_stacktrace(stacktrace)
                })
            }
          )

          reraise(e, stacktrace)
      end
    end
  end
end
