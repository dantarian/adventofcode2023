defmodule Day9 do
  def part1(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(fn line ->
      line |> String.split() |> Enum.map(&String.to_integer(&1)) |> Enum.reverse()
    end)
    |> Enum.map(&find_next(&1))
    |> Enum.sum()
  end

  def part2(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(fn line ->
      line |> String.split() |> Enum.map(&String.to_integer(&1))
    end)
    |> Enum.map(&find_prev(&1))
    |> Enum.sum()
  end

  defp find_next([last | _] = series) do
    cond do
      Enum.all?(series, &(&1 == 0)) ->
        0

      true ->
        last +
          (series
           |> Enum.chunk_every(2, 1, :discard)
           |> Enum.map(fn [a, b | []] -> a - b end)
           |> find_next())
    end
  end

  defp find_prev([first | _] = series) do
    cond do
      Enum.all?(series, &(&1 == 0)) ->
        0

      true ->
        first -
          (series
           |> Enum.chunk_every(2, 1, :discard)
           |> Enum.map(fn [a, b | []] -> b - a end)
           |> find_next())
    end
  end
end
