defmodule Day6 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> find_unique_packet(4)

  def part2(file),
    do:
      file
      |> File.read!()
      |> find_unique_packet(14)

  def find_unique_packet(data, size),
    do:
      data
      |> String.graphemes()
      |> Enum.chunk_every(size, 1)
      |> Enum.with_index(size)
      |> Enum.drop_while(fn {list, _} -> length(Enum.uniq(list)) < size end)
      |> hd()
end
