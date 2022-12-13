defmodule Day12 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> shortest_path()

  def part2(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> reverse_shortest_path()

  defp parse(string),
    do:
      string
      |> String.split("\n")
      |> Enum.with_index()
      |> do_parse(%{}, %{}, nil, nil)

  defp do_parse([], heights, costs, start_point, end_point),
    do: {heights, costs, start_point, end_point}

  defp do_parse([{line, index} | tail], heights, costs, start_point, end_point) do
    {heights, costs, start_point, end_point} =
      parse_line(line, index, heights, costs, start_point, end_point)

    do_parse(tail, heights, costs, start_point, end_point)
  end

  defp parse_line(line, y, heights, costs, start_point, end_point),
    do:
      line
      |> String.to_charlist()
      |> Enum.with_index()
      |> do_parse_line(y, heights, costs, start_point, end_point)

  defp do_parse_line([], _, heights, costs, start_point, end_point),
    do: {heights, costs, start_point, end_point}

  defp do_parse_line([{height, x} | tail], y, heights, costs, start_point, end_point) do
    {height, start_point, end_point} =
      case height do
        ?S -> {?a, {x, y}, end_point}
        ?E -> {?z, start_point, {x, y}}
        c -> {c, start_point, end_point}
      end

    cost = if {x, y} == start_point, do: 0, else: 1_000_000

    do_parse_line(
      tail,
      y,
      Map.put(heights, {x, y}, height),
      Map.put(costs, {x, y}, cost),
      start_point,
      end_point
    )
  end

  defp shortest_path({heights, costs, start_point, end_point}) do
    costs = do_shortest_path(heights, costs, [start_point])
    Map.get(costs, end_point)
  end

  defp do_shortest_path(_, costs, []), do: costs

  defp do_shortest_path(heights, costs, [point | tail]) do
    {current_height, current_cost} = {Map.get(heights, point), Map.get(costs, point)}

    {costs, points_to_consider} =
      find_neighbours(point)
      |> Enum.filter(&Map.has_key?(heights, &1))
      |> Enum.reduce({costs, []}, fn neighbour, {costs, updated_points} ->
        {neighbour_height, neighbour_cost} =
          {Map.get(heights, neighbour), Map.get(costs, neighbour)}

        cond do
          neighbour_height <= current_height + 1 and neighbour_cost > current_cost + 1 ->
            {Map.put(costs, neighbour, current_cost + 1), [neighbour | updated_points]}

          true ->
            {costs, updated_points}
        end
      end)

    do_shortest_path(heights, costs, MapSet.to_list(MapSet.new(points_to_consider ++ tail)))
  end

  defp find_neighbours({x, y}), do: [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]

  defp reverse_shortest_path({heights, costs, start_point, end_point}) do
    minimums = heights |> Enum.filter(fn {_, v} -> v == ?a end) |> Enum.map(fn {k, _} -> k end)

    costs =
      do_reverse_shortest_path(
        heights,
        costs |> Map.put(start_point, 1_000_000) |> Map.put(end_point, 0),
        [end_point]
      )

    costs |> Map.take(minimums) |> Map.values() |> Enum.min()
  end

  defp do_reverse_shortest_path(_, costs, []), do: costs

  defp do_reverse_shortest_path(heights, costs, [point | tail]) do
    {current_height, current_cost} = {Map.get(heights, point), Map.get(costs, point)}

    {costs, points_to_consider} =
      find_neighbours(point)
      |> Enum.filter(&Map.has_key?(heights, &1))
      |> Enum.reduce({costs, []}, fn neighbour, {costs, updated_points} ->
        {neighbour_height, neighbour_cost} =
          {Map.get(heights, neighbour), Map.get(costs, neighbour)}

        cond do
          neighbour_height >= current_height - 1 and neighbour_cost > current_cost + 1 ->
            {Map.put(costs, neighbour, current_cost + 1), [neighbour | updated_points]}

          true ->
            {costs, updated_points}
        end
      end)

    do_reverse_shortest_path(
      heights,
      costs,
      MapSet.to_list(MapSet.new(points_to_consider ++ tail))
    )
  end
end
