defmodule Day4 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
      |> Enum.filter(&fully_overlapping?/1)
      |> length()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
      |> Enum.map(&to_ranges/1)
      |> Enum.reject(fn {a, b} -> Range.disjoint?(a, b) end)
      |> length()

  defp parse_line(line),
    do:
      String.split(line, [",", "-"])
      |> Enum.map(&String.to_integer/1)

  defp to_ranges([start_a, end_a, start_b, end_b]), do: {start_a..end_a, start_b..end_b}

  defp fully_overlapping?([start_a, end_a, start_b, end_b])
       when start_a <= start_b and end_a >= end_b,
       do: true

  defp fully_overlapping?([start_a, end_a, start_b, end_b])
       when start_a >= start_b and end_a <= end_b,
       do: true

  defp fully_overlapping?(_), do: false
end
