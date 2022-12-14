defmodule Day14 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&make_path/1)
      |> Enum.reduce(fn x, acc -> MapSet.union(acc, x) end)
      |> pour_sand()
      |> MapSet.size()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&make_path/1)
      |> Enum.reduce(fn x, acc -> MapSet.union(acc, x) end)
      |> pour_sand_finite()
      |> MapSet.size()

  defp make_path(line),
    do:
      line
      |> String.split(" -> ")
      |> Enum.map(fn x ->
        x |> String.split(",") |> Enum.map(&String.to_integer/1) |> List.to_tuple()
      end)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.flat_map(&path_segment/1)
      |> MapSet.new()

  defp path_segment([{ax, ay}, {bx, by}]) when ax == bx and ay < by,
    do: for(y <- ay..by, do: {ax, y})

  defp path_segment([{ax, ay}, {bx, by}]) when ax == bx and ay > by,
    do: for(y <- by..ay, do: {ax, y})

  defp path_segment([{ax, ay}, {bx, by}]) when ay == by and ax < bx,
    do: for(x <- ax..bx, do: {x, ay})

  defp path_segment([{ax, ay}, {bx, by}]) when ay == by and ax > bx,
    do: for(x <- bx..ax, do: {x, ay})

  defp pour_sand(rocks),
    do:
      do_pour_sand(
        rocks,
        MapSet.new(),
        rocks |> Enum.map(fn {_, y} -> y end) |> Enum.max(),
        {500, 0}
      )

  defp do_pour_sand(_, settled_sand, max_rock_depth, {_, sand_y}) when sand_y >= max_rock_depth,
    do: settled_sand

  defp do_pour_sand(rocks, settled_sand, max_rock_depth, sand) do
    case find_space(rocks, settled_sand, sand) do
      [new_position | _] -> do_pour_sand(rocks, settled_sand, max_rock_depth, new_position)
      [] -> do_pour_sand(rocks, MapSet.put(settled_sand, sand), max_rock_depth, {500, 0})
    end
  end

  defp find_space(rocks, settled_sand, {x, y}),
    do:
      [{x, y + 1}, {x - 1, y + 1}, {x + 1, y + 1}]
      |> Enum.reject(&MapSet.member?(rocks, &1))
      |> Enum.reject(&MapSet.member?(settled_sand, &1))

  defp pour_sand_finite(rocks),
    do:
      do_pour_sand_finite(
        rocks,
        MapSet.new(),
        (rocks |> Enum.map(fn {_, y} -> y end) |> Enum.max()) + 2,
        {500, 0}
      )

  defp do_pour_sand_finite(rocks, settled_sand, floor_depth, sand) do
    case find_space(rocks, settled_sand, floor_depth, sand) do
      [new_position | _] ->
        do_pour_sand_finite(rocks, settled_sand, floor_depth, new_position)

      [] ->
        if sand == {500, 0},
          do: MapSet.put(settled_sand, sand),
          else: do_pour_sand_finite(rocks, MapSet.put(settled_sand, sand), floor_depth, {500, 0})
    end
  end

  defp find_space(_, _, floor_depth, {_, y}) when y + 1 == floor_depth, do: []

  defp find_space(rocks, settled_sand, _, {x, y}),
    do:
      [{x, y + 1}, {x - 1, y + 1}, {x + 1, y + 1}]
      |> Enum.reject(&MapSet.member?(rocks, &1))
      |> Enum.reject(&MapSet.member?(settled_sand, &1))
end
