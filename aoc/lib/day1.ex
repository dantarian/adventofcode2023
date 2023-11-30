defmodule Day1 do
  def part1(file) do
    file |> File.read!() |> String.split("\n") |> do_something()
  end

  defp do_something(list), do: list

  def part2(file) do
    file |> File.read!() |> String.split("\n") |> do_something_else()
  end

  defp do_something_else(list), do: list
end
