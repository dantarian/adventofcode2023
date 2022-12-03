defmodule Day3 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&bisect/1)
      |> Enum.map(&common_character/1)
      |> Enum.map(&priority/1)
      |> Enum.sum()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.chunk_every(3)
      |> Enum.map(&common_character/1)
      |> Enum.map(&priority/1)
      |> Enum.sum()

  defp bisect(str) do
    half = div(byte_size(str), 2)

    [
      binary_part(str, 0, half),
      binary_part(str, half, half)
    ]
  end

  defp common_character(list) do
    list
    |> Enum.map(fn x -> String.to_charlist(x) |> MapSet.new() end)
    |> Enum.reduce(&MapSet.intersection/2)
    |> Enum.at(0)
  end

  defp priority(char) when char in ?a..?z, do: char - ?a + 1
  defp priority(char) when char in ?A..?Z, do: char - ?A + 27
end
