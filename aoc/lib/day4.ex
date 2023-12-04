defmodule Day4 do
  def part1(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(fn line ->
      [_, content | []] = String.split(line, ": ")
      [winners, candidates | []] = String.split(content, " | ")
      winners = winners |> String.split() |> MapSet.new()
      candidates = candidates |> String.split() |> MapSet.new()
      matches = MapSet.intersection(winners, candidates) |> MapSet.to_list() |> length()

      case matches do
        0 -> 0
        n -> :math.pow(2, n - 1)
      end
    end)
    |> Enum.sum()
  end
end
