defmodule Day1 do
  def part1(file) do
    file |> AOCUtil.lines!() |> digits()
  end

  defp digits(list), do: do_digits(list, [])

  defp do_digits([], results), do: Enum.sum(results)

  defp do_digits([line | rest], results),
    do: do_digits(rest, [line |> to_charlist() |> line_digits() | results])

  defp line_digits(clist), do: do_line_digits(clist, :null, :null)

  defp do_line_digits([], :null, :null), do: 0
  defp do_line_digits([], first, last), do: 10 * (first - ?0) + (last - ?0)

  defp do_line_digits([c | rest], :null, :null) when c >= ?0 and c <= ?9,
    do: do_line_digits(rest, c, c)

  defp do_line_digits([c | rest], first, _) when c >= ?0 and c <= ?9,
    do: do_line_digits(rest, first, c)

  defp do_line_digits([_ | rest], first, last), do: do_line_digits(rest, first, last)

  def part2(file) do
    file |> AOCUtil.lines!() |> text_digits()
  end

  defp text_digits(list), do: do_text_digits(list, [])

  defp do_text_digits([], results), do: Enum.sum(results)

  defp do_text_digits([line | rest], results),
    do: do_text_digits(rest, [line |> to_charlist() |> line_text_digits() | results])

  defp line_text_digits(clist), do: do_line_text_digits(clist, :null, :null)

  defp do_line_text_digits([], :null, :null), do: 0
  defp do_line_text_digits([], first, last), do: 10 * (first - ?0) + (last - ?0)

  defp do_line_text_digits([c | rest], :null, :null) when c >= ?0 and c <= ?9,
    do: do_line_text_digits(rest, c, c)

  defp do_line_text_digits([c | rest], first, _) when c >= ?0 and c <= ?9,
    do: do_line_text_digits(rest, first, c)

  defp do_line_text_digits([?o | [?n | [?e | rest]]], first, last),
    do: do_line_text_digits([?1 | [?e | rest]], first, last)

  defp do_line_text_digits([?t | [?w | [?o | rest]]], first, last),
    do: do_line_text_digits([?2 | [?o | rest]], first, last)

  defp do_line_text_digits([?t | [?h | [?r | [?e | [?e | rest]]]]], first, last),
    do: do_line_text_digits([?3 | [?e | rest]], first, last)

  defp do_line_text_digits([?f | [?o | [?u | [?r | rest]]]], first, last),
    do: do_line_text_digits([?4 | rest], first, last)

  defp do_line_text_digits([?f | [?i | [?v | [?e | rest]]]], first, last),
    do: do_line_text_digits([?5 | [?e | rest]], first, last)

  defp do_line_text_digits([?s | [?i | [?x | rest]]], first, last),
    do: do_line_text_digits([?6 | rest], first, last)

  defp do_line_text_digits([?s | [?e | [?v | [?e | [?n | rest]]]]], first, last),
    do: do_line_text_digits([?7 | [?n | rest]], first, last)

  defp do_line_text_digits([?e | [?i | [?g | [?h | [?t | rest]]]]], first, last),
    do: do_line_text_digits([?8 | [?t | rest]], first, last)

  defp do_line_text_digits([?n | [?i | [?n | [?e | rest]]]], first, last),
    do: do_line_text_digits([?9 | [?e | rest]], first, last)

  defp do_line_text_digits([_ | rest], first, last), do: do_line_text_digits(rest, first, last)
end
