defmodule Snafu do
  def parse(str), do: str |> String.to_charlist() |> do_parse(0)

  defp do_parse([], result), do: result
  defp do_parse([?2 | rest], result), do: do_parse(rest, result * 5 + 2)
  defp do_parse([?1 | rest], result), do: do_parse(rest, result * 5 + 1)
  defp do_parse([?0 | rest], result), do: do_parse(rest, result * 5)
  defp do_parse([?- | rest], result), do: do_parse(rest, result * 5 - 1)
  defp do_parse([?= | rest], result), do: do_parse(rest, result * 5 - 2)

  def to_snafu(value), do: do_to_snafu([], value)

  defp map_digit(2), do: ?2
  defp map_digit(1), do: ?1
  defp map_digit(0), do: ?0
  defp map_digit(-1), do: ?-
  defp map_digit(-2), do: ?=

  defp do_to_snafu([], 0), do: [?0]
  defp do_to_snafu(charlist, 0), do: charlist

  defp do_to_snafu(charlist, value) do
    {digit, remainder} =
      case rem(value, 5) do
        4 -> {map_digit(-1), div(value, 5) + 1}
        3 -> {map_digit(-2), div(value, 5) + 1}
        x -> {map_digit(x), div(value, 5)}
      end

    do_to_snafu([digit | charlist], remainder)
  end
end

defmodule Day25 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&Snafu.parse/1)
      |> Enum.sum()
      |> Snafu.to_snafu()
end
