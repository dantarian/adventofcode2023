defmodule AOCUtil do
  def manhattan({ax, ay}, {bx, by}), do: abs(ax - bx) + abs(ay - by)
  def lines!(file), do: file |> File.read!() |> String.split("\n")
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

  def put_if_lesser(candidate),
    do:
      Agent.update(__MODULE__, fn state ->
        if candidate < state, do: IO.inspect(candidate), else: state
      end)

  def stop, do: Agent.stop(__MODULE__)
end

defmodule Cache do
  use Agent

  def start_link(), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def has_key?(key), do: Agent.get(__MODULE__, fn map -> Map.has_key?(map, key) end)

  def get(key), do: Agent.get(__MODULE__, fn map -> Map.get(map, key) end)

  def put(key, value), do: Agent.update(__MODULE__, fn map -> Map.put(map, key, value) end)

  def stop, do: Agent.stop(__MODULE__)
end
