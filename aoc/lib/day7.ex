defmodule Day7 do
  @cards %{
    ?2 => 1,
    ?3 => 2,
    ?4 => 3,
    ?5 => 4,
    ?6 => 5,
    ?7 => 6,
    ?8 => 7,
    ?9 => 8,
    ?T => 9,
    ?J => 10,
    ?Q => 11,
    ?K => 12,
    ?A => 13
  }

  @cards2 %{
    ?J => 0,
    ?2 => 1,
    ?3 => 2,
    ?4 => 3,
    ?5 => 4,
    ?6 => 5,
    ?7 => 6,
    ?8 => 7,
    ?9 => 8,
    ?T => 9,
    ?Q => 11,
    ?K => 12,
    ?A => 13
  }

  @hands %{
    [5 | []] => 7,
    [4, 1 | []] => 6,
    [3, 2 | []] => 5,
    [3, 1, 1 | []] => 4,
    [2, 2, 1 | []] => 3,
    [2, 1, 1, 1 | []] => 2,
    [1, 1, 1, 1, 1 | []] => 1
  }

  def part1(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.map(fn line ->
        line
        |> String.split()
        |> then(fn [hand, bid] -> {parse_hand(hand), String.to_integer(bid)} end)
      end)
      |> Enum.sort()
      |> Enum.with_index(1)
      |> Enum.reduce(0, fn {{_, bid}, index}, acc -> acc + bid * index end)

  defp parse_hand(hand),
    do:
      hand
      |> String.to_charlist()
      |> Enum.map(fn x -> @cards[x] end)
      |> then(fn list ->
        [
          @hands[Enum.frequencies(list) |> Enum.map(fn {_, b} -> b end) |> Enum.sort(:desc)]
          | list
        ]
      end)

  def part2(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.map(fn line ->
        line
        |> String.split()
        |> then(fn [hand, bid] -> {parse_hand2(hand), String.to_integer(bid)} end)
      end)
      |> Enum.sort()
      |> Enum.with_index(1)
      |> Enum.reduce(0, fn {{_, bid}, index}, acc -> acc + bid * index end)

  defp parse_hand2(hand),
    do:
      hand
      |> String.to_charlist()
      |> Enum.map(fn x -> @cards2[x] end)
      |> then(fn list ->
        jokers = list |> Enum.count(fn x -> x == 0 end)

        [
          @hands[Enum.frequencies(list) |> Enum.map(fn {_, b} -> b end) |> Enum.sort(:desc)]
          |> apply_jokers(jokers)
          | list
        ]
      end)

  defp apply_jokers(x, 0), do: x
  defp apply_jokers(7, _), do: 7
  defp apply_jokers(6, _), do: 7
  defp apply_jokers(5, _), do: 7
  defp apply_jokers(4, _), do: 6
  defp apply_jokers(3, 2), do: 6
  defp apply_jokers(3, 1), do: 5
  defp apply_jokers(2, _), do: 4
  defp apply_jokers(1, _), do: 2
end
