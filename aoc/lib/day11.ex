defmodule Day11 do
  def part1(file) do
    galaxies = parse(file)
    {empty_rows, empty_cols} = find_empty(galaxies)

    distances(galaxies, empty_rows, empty_cols)
  end

  def part2(file, expansion_factor \\ 1_000_000) do
    galaxies = parse(file)
    {empty_rows, empty_cols} = find_empty(galaxies)

    distances(galaxies, empty_rows, empty_cols, expansion_factor - 1)
  end

  defp parse(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        line
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.map(fn {c, x} ->
          case c do
            ?. -> nil
            ?# -> {x, y}
          end
        end)
        |> Enum.reject(fn x -> x == nil end)
      end)

  defp find_empty(points) do
    {{x_min, _}, {x_max, _}} = points |> Enum.min_max_by(fn {x, _} -> x end)
    {{_, y_min}, {_, y_max}} = points |> Enum.min_max_by(fn {_, y} -> y end)
    used_cols = points |> Enum.map(fn {x, _} -> x end) |> MapSet.new()
    used_rows = points |> Enum.map(fn {_, y} -> y end) |> MapSet.new()

    {y_min..y_max |> MapSet.new() |> MapSet.difference(used_rows),
     x_min..x_max |> MapSet.new() |> MapSet.difference(used_cols)}
  end

  defp distances(galaxies, empty_rows, empty_cols, expansion_factor \\ 1),
    do: do_distances(galaxies, empty_rows, empty_cols, expansion_factor, 0)

  defp do_distances([], _, _, _, total), do: total

  defp do_distances([point | rest], empty_rows, empty_cols, expansion_factor, total),
    do:
      do_distances(
        rest,
        empty_rows,
        empty_cols,
        expansion_factor,
        total + point_distances(point, rest, empty_rows, empty_cols, expansion_factor)
      )

  defp point_distances(point, others, empty_rows, empty_cols, expansion_factor),
    do: do_point_distances(point, others, empty_rows, empty_cols, expansion_factor, 0)

  defp do_point_distances(_, [], _, _, _, total), do: total

  defp do_point_distances(
         {x1, y1} = p1,
         [{x2, y2} = p2 | rest],
         empty_rows,
         empty_cols,
         expansion_factor,
         total
       ) do
    empty_x = count_empty(x1, x2, empty_cols)
    empty_y = count_empty(y1, y2, empty_rows)

    do_point_distances(
      p1,
      rest,
      empty_rows,
      empty_cols,
      expansion_factor,
      total + AOCUtil.manhattan(p1, p2) + empty_x * expansion_factor + empty_y * expansion_factor
    )
  end

  defp count_empty(a, b, known_empty),
    do: min(a, b)..max(a, b) |> MapSet.new() |> MapSet.intersection(known_empty) |> MapSet.size()
end
