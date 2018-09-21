defmodule Crew.Support.Assertions do
  import ExUnit.Assertions

  def assert_eventually(f, total \\ 0) do
    case f.() do
      true ->
        assert true

      false when total < 100 ->
        :timer.sleep(10)
        assert_eventually(f, total + 5)

      false ->
        flunk("expected condition to eventually be true")
    end
  end
end
