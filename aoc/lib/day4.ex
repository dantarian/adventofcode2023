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

  def part2(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn line, acc ->
      [id, content | []] = String.split(line, ": ")
      [_, id | []] = String.split(id)
      id = String.to_integer(id)
      [winners, candidates | []] = String.split(content, " | ")
      winners = winners |> String.split() |> MapSet.new()
      candidates = candidates |> String.split() |> MapSet.new()
      matches = MapSet.intersection(winners, candidates) |> MapSet.to_list() |> length()

      Map.put(
        acc,
        id,
        case matches do
          0 -> 1
          n -> 1 + (for(x <- (id + 1)..(id + n), do: Map.get(acc, x)) |> Enum.sum())
        end
      )
    end)
    |> Map.values()
    |> Enum.sum()
  end
end
