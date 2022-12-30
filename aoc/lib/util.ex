defmodule AOCUtil do
  def manhattan({ax, ay}, {bx, by}), do: abs(ax - bx) + abs(ay - by)
end

defmodule BestResult do
  use Agent

  def start_link(initial_value), do: Agent.start_link(fn -> initial_value end, name: __MODULE__)

  def value, do: Agent.get(__MODULE__, fn state -> state end)

  def put_if_greater(candidate),
    do:
      Agent.update(__MODULE__, fn state ->
        if candidate > state, do: IO.inspect(candidate), else: state
      end)

  def stop, do: Agent.stop(__MODULE__)
end
