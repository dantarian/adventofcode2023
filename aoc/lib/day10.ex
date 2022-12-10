defmodule Day10 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.flat_map(fn x ->
        case x do
          "noop" -> [0]
          <<?a, ?d, ?d, ?x, ?\s, val::binary>> -> [0, String.to_integer(val)]
        end
      end)
      |> Enum.scan(1, &+/2)
      # Want the index to correlate with the beginning of a cycle.
      |> Enum.with_index(2)
      |> Enum.drop(18)
      |> Enum.take_every(40)
      |> Enum.reduce(0, fn {val, idx}, acc -> acc + val * idx end)

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.flat_map(fn x ->
        case x do
          "noop" -> [0]
          <<?a, ?d, ?d, ?x, ?\s, val::binary>> -> [0, String.to_integer(val)]
        end
      end)
      |> Enum.scan(1, &+/2)
      |> then(&[1 | &1])
      |> Enum.chunk_every(40)
      |> Enum.map(&render/1)
      |> Enum.each(&IO.puts(to_string(&1)))

  defp render(list),
    do:
      Enum.with_index(list)
      |> Enum.map(fn {val, idx} -> if abs(val - idx) <= 1, do: ?█, else: ?\s end)
end
