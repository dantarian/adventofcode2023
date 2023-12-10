defmodule Day10 do
  @search_order %{
    north: :east,
    east: :south,
    south: :west
  }

  def part1(file) do
    file |> parse() |> loop_length() |> then(fn x -> x / 2 end)
  end

  def part2(file) do
    file |> parse() |> points_inside_loop()
  end

  defp parse(file) do
    map =
      file
      |> AOCUtil.lines!()
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        line
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.map(fn {c, x} ->
          case c do
            ?- -> {{x, y}, %{west: :west, east: :east, symbol: ?─}}
            ?| -> {{x, y}, %{north: :north, south: :south, symbol: ?│}}
            ?7 -> {{x, y}, %{north: :west, east: :south, symbol: ?┐}}
            ?J -> {{x, y}, %{south: :west, east: :north, symbol: ?┘}}
            ?L -> {{x, y}, %{south: :east, west: :north, symbol: ?└}}
            ?F -> {{x, y}, %{north: :east, west: :south, symbol: ?┌}}
            ?S -> {{x, y}, :start}
            _ -> nil
          end
        end)
        |> Enum.filter(fn x -> x end)
      end)
      |> Map.new()

    {sx, sy} =
      map
      |> Map.filter(fn {{_, _}, val} -> val == :start end)
      |> Map.keys()
      |> hd()

    map =
      Map.put(
        map,
        {sx, sy},
        cond do
          Map.get(map, {sx - 1, sy}) |> Map.has_key?(:west) &&
              Map.get(map, {sx + 1, sy}) |> Map.has_key?(:east) ->
            %{west: :east, east: :west, symbol: ?─}

          Map.get(map, {sx, sy - 1}) |> Map.has_key?(:north) &&
              Map.get(map, {sx, sy + 1}) |> Map.has_key?(:south) ->
            %{north: :south, south: :north, symbol: ?│}

          Map.get(map, {sx - 1, sy}) |> Map.has_key?(:west) &&
              Map.get(map, {sx, sy + 1}) |> Map.has_key?(:south) ->
            %{north: :west, east: :south, symbol: ?┐}

          Map.get(map, {sx - 1, sy}) |> Map.has_key?(:west) &&
              Map.get(map, {sx, sy - 1}) |> Map.has_key?(:north) ->
            %{south: :west, east: :north, symbol: ?┘}

          Map.get(map, {sx + 1, sy}) |> Map.has_key?(:east) &&
              Map.get(map, {sx, sy - 1}) |> Map.has_key?(:north) ->
            %{south: :east, west: :north, symbol: ?└}

          Map.get(map, {sx + 1, sy}) |> Map.has_key?(:east) &&
              Map.get(map, {sx, sy + 1}) |> Map.has_key?(:south) ->
            %{north: :east, west: :south, symbol: ?┌}
        end
      )

    {{sx, sy}, map}
  end

  defp loop_length({{sx, sy}, map}) do
    do_loop_length({sx, sy}, {sx, sy}, map, 0, :north)
  end

  defp do_loop_length({_, _} = pt, {_, _} = start, _, steps, _) when pt == start and steps > 0,
    do: steps

  defp do_loop_length({_, _} = pt, {_, _} = start, map, 0, direction)
       when pt == start do
    case(Map.get(map, next_point(pt, direction))) do
      %{^direction => _} -> do_loop_length(next_point(pt, direction), start, map, 1, direction)
      _ -> do_loop_length(pt, start, map, 0, Map.get(@search_order, direction))
    end
  end

  defp do_loop_length({_, _} = pt, {_, _} = start, map, steps, direction) do
    ends = Map.get(map, pt)
    new_direction = Map.get(ends, direction)
    do_loop_length(next_point(pt, new_direction), start, map, steps + 1, new_direction)
  end

  defp next_point({x, y}, :north), do: {x, y - 1}
  defp next_point({x, y}, :south), do: {x, y + 1}
  defp next_point({x, y}, :east), do: {x + 1, y}
  defp next_point({x, y}, :west), do: {x - 1, y}

  defp points_inside_loop({start, map}) do
    loop_locations = isolate_loop(start, map)
    {{x_min, _}, {x_max, _}} = Enum.min_max_by(loop_locations, fn {x, _} -> x end)
    {{_, y_min}, {_, y_max}} = Enum.min_max_by(loop_locations, fn {_, y} -> y end)

    for y <- y_min..y_max, into: [] do
      for x <- x_min..x_max, into: [] do
        if MapSet.member?(loop_locations, {x, y}) do
          case Map.get(map, {x, y}) do
            %{symbol: symbol} -> symbol
            _ -> ?\s
          end
        else
          ?\s
        end
      end
      |> List.to_string()
      |> String.trim()
      |> String.replace("─", "")
      |> String.replace("┌┐", "")
      |> String.replace("└┘", "")
      |> String.replace("└┐", "│")
      |> String.replace("┌┘", "│")
      |> String.split("│")
      |> tl()
      |> Enum.take_every(2)
      |> Enum.map(&String.length(&1))
      |> Enum.sum()
    end
    |> Enum.sum()
  end

  defp isolate_loop(start, map) do
    do_isolate_loop(start, start, map, [], :north)
  end

  defp do_isolate_loop({_, _} = pt, {_, _} = start, _, steps, _)
       when pt == start and length(steps) > 0,
       do: MapSet.new(steps)

  defp do_isolate_loop({_, _} = pt, {_, _} = start, map, [], direction)
       when pt == start do
    case(Map.get(map, next_point(pt, direction))) do
      %{^direction => _} ->
        do_isolate_loop(next_point(pt, direction), start, map, [start], direction)

      _ ->
        do_isolate_loop(pt, start, map, [], Map.get(@search_order, direction))
    end
  end

  defp do_isolate_loop({_, _} = pt, {_, _} = start, map, steps, direction) do
    ends = Map.get(map, pt)
    new_direction = Map.get(ends, direction)
    do_isolate_loop(next_point(pt, new_direction), start, map, [pt | steps], new_direction)
  end
end
