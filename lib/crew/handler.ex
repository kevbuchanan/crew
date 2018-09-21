defmodule Crew.Handler do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: :macros

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def perform(_job), do: :ok
    end
  end

  defmacro job(name, struct_def) do
    quote do
      defmodule unquote(name) do
        defstruct unquote(struct_def)

        def perform(job) do
          unquote(__CALLER__.module).perform(job)
        end
      end
    end
  end
end
