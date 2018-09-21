defmodule Crew.Logger do
  require Logger

  defmacro __using__(_) do
    quote do
      require Logger
      require Crew.Logger.Instrument

      import unquote(__MODULE__)
      import Crew.Logger.Instrument
    end
  end

  def complete(event_name, properties) do
    Logger.info(
      "#{event_name} complete - #{inspect(properties)}",
      event: %{
        name: "#{event_name}.Complete",
        properties: properties
      }
    )
  end

  def failed(event_name, reason, properties) do
    Logger.info(
      "#{event_name} failed - #{inspect(reason)}",
      event: %{
        name: "#{event_name}.Failed",
        properties:
          Map.merge(properties, %{
            error: inspect(reason)
          })
      }
    )
  end

  def log_event(name, properties) do
    Logger.info(
      "#{name} - #{inspect(properties)}",
      event: %{
        name: name,
        properties: properties
      }
    )
  end
end
