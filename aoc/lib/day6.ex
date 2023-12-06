defmodule Day6 do
  def part1(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.map(&String.split(&1))
    |> Enum.map(fn [_ | rest] ->
      rest
      |> Enum.map(&String.to_integer(&1))
    end)
    |> Enum.zip()
    |> Enum.map(&wins(&1))
    |> Enum.product()
  end

  def part2(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.map(fn line ->
      line |> String.split() |> tl() |> Enum.join() |> String.to_integer()
    end)
    |> then(fn [time, distance] -> wins({time, distance}) end)
  end

  defp wins({time, distance}) do
    0..time
    |> Enum.map(fn hold -> hold * (time - hold) end)
    |> Enum.filter(fn result -> result > distance end)
    |> length()
  end
end
