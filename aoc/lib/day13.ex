defmodule Day13 do
  def part1(file) do
    blocks = file |> parse()
    h = blocks |> Enum.map(&h_symmetry/1) |> Enum.sum()
    v = blocks |> Enum.map(&v_symmetry/1) |> Enum.sum()
    h + 100 * v
  end

  def part2(file) do
    blocks = file |> parse()
    h = blocks |> Enum.map(fn block -> block |> h_symmetry(&find_near_symmetry/1) end) |> Enum.sum()
    v = blocks |> Enum.map(fn block -> block |> v_symmetry(&find_near_symmetry/1) end) |> Enum.sum()
    h + 100 * v
  end

  defp parse(file) do
    file
    |> AOCUtil.blocks!() 
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.map(fn block -> 
      rows = block
      |> String.split("\n")
      |> Enum.with_index(1)
      
      map = rows
      |> Enum.reduce(%{}, fn {row, y}, acc ->
        row
          |> String.to_charlist()
          |> Enum.with_index(1)
          |> Enum.reduce(acc, fn {c, x}, acc -> Map.put(acc, {x, y}, c) end)
      end)

      %{
        y_max: map |> Map.keys() |> Enum.map(fn {_, y} -> y end) |> Enum.max(),
        x_max: map |> Map.keys() |> Enum.map(fn {x, _} -> x end) |> Enum.max(),
        map: map
      }
    end)
  end

  defp h_symmetry(%{y_max: y_max, x_max: x_max, map: %{} = map}, finder \\ &find_symmetry/1) do
    cols = for x <- 1..x_max, into: [] do
      for y <- 1..y_max, into: [] do
        map |> Map.get({x, y})
      end |> List.to_string()
    end

    finder.(cols)
  end

  defp v_symmetry(%{y_max: y_max, x_max: x_max, map: %{} = map}, finder \\ &find_symmetry/1) do
    rows = for y <- 1..y_max, into: [] do
      for x <- 1..x_max, into: [] do
        map |> Map.get({x, y})
      end |> List.to_string()
    end

    finder.(rows)
  end

  defp find_symmetry(list), do: do_find_symmetry(list, [])

  defp do_find_symmetry([], _), do: 0
  defp do_find_symmetry([next | rest], [last | other_previous] = previous) when next == last do
    if confirm_symmetry(rest, other_previous), do: length(previous), else: do_find_symmetry(rest, [next | previous])
  end
  defp do_find_symmetry([next | rest], previous), do: do_find_symmetry(rest, [next | previous])

  defp confirm_symmetry(remaining, previous), do: Enum.zip(remaining, previous) |> Enum.all?(fn {a, b} -> a == b end)

  defp find_near_symmetry(list), do: do_find_near_symmetry(list, [])
  defp do_find_near_symmetry([], _), do: 0
  defp do_find_near_symmetry([next | rest], []), do: do_find_near_symmetry(rest, [next])
  defp do_find_near_symmetry([next | rest] = list, previous) do
    if check_near_symmetry(list, previous), do: length(previous), else: do_find_near_symmetry(rest, [next | previous])
  end

  defp check_near_symmetry(list, previous), do:
    (Enum.zip(list, previous) |> Enum.map(fn {x, y} -> Levenshtein.distance(x, y) end) |> Enum.sum()) == 1
end
