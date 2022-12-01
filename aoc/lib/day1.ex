defmodule Day1 do
  def part1(file) do
    file |> File.read!() |> String.split("\n") |> max_elf({0, 0})
  end

  defp max_elf(list, {mx, curr}) when list == [], do: max(mx, curr)
  defp max_elf([head | tail], {mx, curr}) when head == "", do: max_elf(tail, {max(mx, curr), 0})
  defp max_elf([head | tail], {mx, curr}), do: max_elf(tail, {mx, curr + String.to_integer(head)})

  def part2(file) do
    file |> File.read!() |> String.split("\n") |> max_three({[0, 0, 0], 0})
  end

  defp replace_least_if_greater(list, new), do: [new | list] |> Enum.sort() |> tl

  defp max_three(list, {mx, curr}) when list == [],
    do: Enum.sum(replace_least_if_greater(mx, curr))

  defp max_three([head | tail], {mx, curr}) when head == "",
    do: max_three(tail, {replace_least_if_greater(mx, curr), 0})

  defp max_three([head | tail], {mx, curr}),
    do: max_three(tail, {mx, curr + String.to_integer(head)})
end
