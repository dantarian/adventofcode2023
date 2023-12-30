defmodule Day18 do
  defmodule Segment do
    defstruct [:start_point, :end_point, :orientation, :type]

    def h_range(%Segment{orientation: :horizontal} = segment) do
      {x1, _} = segment.start_point
      {x2, _} = segment.end_point
      x1..x2
    end
  end

  def part1(file),
    do: file |> parse() |> dig() |> fill() |> map_size()

  def part2(file),
    do:
      file
      |> parse_alt()
      |> make_segments()
      |> volume()

  defp parse(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.map(fn line ->
        [direction, distance, _] = line |> String.split()

        {case direction do
           "U" -> :up
           "D" -> :down
           "L" -> :left
           "R" -> :right
         end, String.to_integer(distance)}
      end)

  defp parse_alt(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.map(fn line ->
        [distance, direction] = Regex.run(~r/.*#(.{5})(.).*/, line, capture: :all_but_first)

        {case direction do
           "0" -> :right
           "1" -> :down
           "2" -> :left
           "3" -> :up
         end, String.to_integer(distance, 16)}
      end)

  defp dig(instructions), do: do_dig(instructions, MapSet.new({0, 0}), {0, 0})

  defp do_dig([], map, _), do: map
  defp do_dig([{_, 0} | rest], map, position), do: do_dig(rest, map, position)

  defp do_dig([{direction, distance} | rest], map, position) do
    position = next_position(position, direction)
    do_dig([{direction, distance - 1} | rest], map |> MapSet.put(position), position)
  end

  defp next_position({x, y}, :up), do: {x, y - 1}
  defp next_position({x, y}, :down), do: {x, y + 1}
  defp next_position({x, y}, :left), do: {x - 1, y}
  defp next_position({x, y}, :right), do: {x + 1, y}

  defp make_segments(instructions) do
    first_instruction = instructions |> List.first()
    last_instruction = instructions |> List.last()

    ([last_instruction] ++ instructions ++ [first_instruction])
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.reduce({[], {0, 0}}, fn [
                                      {entry_direction, _},
                                      {direction, distance},
                                      {exit_direction, _}
                                    ],
                                    {result, {x, y}} ->
      type = if entry_direction == exit_direction, do: :s_bend, else: :u_bend

      orientation =
        case direction do
          :left -> :horizontal
          :right -> :horizontal
          :up -> :vertical
          :down -> :vertical
        end

      target_point = target({x, y}, direction, distance)
      [start_point, end_point] = [{x, y}, target_point] |> Enum.sort()

      {[
         %Segment{
           start_point: start_point,
           end_point: end_point,
           orientation: orientation,
           type: type
         }
         | result
       ], target_point}
    end)
    |> then(&elem(&1, 0))
  end

  defp target({x, y}, :left, distance), do: {x - distance, y}
  defp target({x, y}, :right, distance), do: {x + distance, y}
  defp target({x, y}, :up, distance), do: {x, y - distance}
  defp target({x, y}, :down, distance), do: {x, y + distance}

  defp fill(%{} = map) do
    y_min = map |> Enum.map(&elem(&1, 1)) |> Enum.min()

    x_min_in_first_row =
      map
      |> Enum.filter(fn {_, y} -> y == y_min end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.min()

    do_fill([{x_min_in_first_row + 1, y_min + 1}], map)
  end

  defp do_fill([], map), do: map

  defp do_fill([head | rest], map) do
    if map |> Map.has_key?(head),
      do: do_fill(rest, map),
      else: do_fill(neighbours(head) ++ rest, map |> MapSet.put(head))
  end

  defp neighbours({x, y}), do: [{x - 1, y}, {x + 1, y}, {x, y - 1}, {x, y + 1}]

  defp volume(segments) do
    segments
    |> Enum.filter(fn %Segment{orientation: orientation} -> orientation == :horizontal end)
    |> Enum.group_by(fn %Segment{start_point: {_, y}} -> y end)
    |> Enum.map(fn {y, segments} ->
      {y, segments |> Enum.sort_by(fn %Segment{start_point: {x, _}} -> x end)}
    end)
    |> Enum.sort_by(fn {y, _} -> y end)
    |> Enum.reduce({0, nil, []}, fn {y, segments}, {acc, previous_y, ranges} ->
      acc =
        acc +
          if previous_y == nil,
            do: 0,
            else: (ranges |> Enum.map(&Range.size/1) |> Enum.sum()) * (y - (previous_y + 1))

      acc = acc + line_width(ranges, segments)
      {acc, y, update_ranges(ranges, segments)}
    end)
    |> then(&elem(&1, 0))
  end

  defp line_width(ranges, segments), do: do_line_width(ranges, segments, 0)

  defp do_line_width([], segments, total) do
    total + (segments |> Enum.map(&Segment.h_range/1) |> Enum.map(&Range.size/1) |> Enum.sum())
  end

  defp do_line_width(ranges, [], total) do
    total + (ranges |> Enum.map(&Range.size/1) |> Enum.sum())
  end

  defp do_line_width([range | ranges], [segment | segments], total) do
    segment_range = Segment.h_range(segment)

    cond do
      range.last < segment_range.first ->
        do_line_width(ranges, [segment | segments], total + Range.size(range))

      segment_range.last < range.first ->
        do_line_width([range | ranges], segments, total + Range.size(segment_range))

      segment.type == :s_bend and range.first == segment_range.last ->
        do_line_width([segment_range.first..range.last | ranges], segments, total)

      segment.type == :s_bend and range.first == segment_range.first ->
        do_line_width([range | ranges], segments, total)

      segment.type == :u_bend and range.first == segment_range.first and
          range.last == segment_range.last ->
        do_line_width([range | ranges], segments, total)

      segment.type == :s_bend and range.last == segment_range.last ->
        do_line_width([range | ranges], segments, total)

      segment.type == :s_bend and range.last == segment_range.first ->
        do_line_width([range.first..segment_range.last | ranges], segments, total)

      segment.type == :u_bend and range.last == segment_range.first ->
        new_segment = %{
          segment
          | start_point: {range.first, elem(segment.start_point, 1)},
            type: :s_bend
        }

        do_line_width(ranges, [new_segment | segments], total)

      segment.type == :u_bend and range.first < segment_range.first and
          range.last > segment_range.last ->
        do_line_width([range | ranges], segments, total)
    end
  end

  defp update_ranges(ranges, segments), do: do_update_ranges(ranges, segments, [])

  defp do_update_ranges([], [], results), do: results |> Enum.reverse()

  defp do_update_ranges([], [segment | segments], results),
    do: do_update_ranges([], segments, [Segment.h_range(segment) | results])

  defp do_update_ranges([range | ranges], [], results),
    do: do_update_ranges(ranges, [], [range | results])

  defp do_update_ranges([range | ranges], [segment | segments], results) do
    segment_range = Segment.h_range(segment)

    cond do
      range.last < segment_range.first ->
        do_update_ranges(ranges, [segment | segments], [range | results])

      segment_range.last < range.first ->
        do_update_ranges([range | ranges], segments, [segment_range | results])

      segment.type == :s_bend and range.first == segment_range.last ->
        do_update_ranges([segment_range.first..range.last | ranges], segments, results)

      segment.type == :s_bend and range.first == segment_range.first ->
        do_update_ranges([segment_range.last..range.last | ranges], segments, results)

      segment.type == :u_bend and range.first == segment_range.first and
          range.last == segment_range.last ->
        do_update_ranges(ranges, segments, results)

      segment.type == :s_bend and range.last == segment_range.last ->
        do_update_ranges([range.first..segment_range.first | ranges], segments, results)

      segment.type == :s_bend and range.last == segment_range.first ->
        do_update_ranges([range.first..segment_range.last | ranges], segments, results)

      segment.type == :u_bend and range.last == segment_range.first ->
        new_segment = %{
          segment
          | start_point: {range.first, elem(segment.start_point, 1)},
            type: :s_bend
        }

        do_update_ranges(ranges, [new_segment | segments], results)

      segment.type == :u_bend and range.first < segment_range.first and
          range.last > segment_range.last ->
        do_update_ranges([segment_range.last..range.last | ranges], segments, [
          range.first..segment_range.first | results
        ])
    end
  end
end
