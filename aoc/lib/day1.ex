defmodule Day1 do
  def part1(file) do
    file |> File.read!() |> String.split("\n") |> digits()
  end

  defp digits(list), do: do_digits(list, [])

  defp do_digits([], results), do: Enum.sum(results)
  defp do_digits([line | rest], results), do: do_digits(rest, [line |> to_charlist() |> line_digits() | results])

  defp line_digits(clist), do: do_line_digits(clist, :null, :null)

  defp do_line_digits([], :null, :null), do: 0
  defp do_line_digits([], first, last), do: (10 * (first - ?0)) + (last - ?0)
  defp do_line_digits([c | rest], :null, :null) when c >= ?0 and c <= ?9, do: do_line_digits(rest, c, c)
  defp do_line_digits([c | rest], first, _) when c >= ?0 and c <= ?9, do: do_line_digits(rest, first, c)
  defp do_line_digits([_ | rest], first, last), do: do_line_digits(rest, first, last)

  def part2(file) do
    file |> File.read!() |> String.split("\n") |> do_something_else()
  end

  defp do_something_else(list), do: list
end
