defmodule Day14 do
  def part1(file) do
    file |> parse() |> with_vertical_ranges() |> tilt_north() |> score()
  end

  def part2(file, iterations) do
    data =
      file
      |> parse()
      |> with_vertical_ranges()
      |> with_horizontal_ranges()
      |> Map.put(:history, %{})

    1..iterations
    |> Enum.reduce(data, fn n, %{history: history} = data ->
      data = data |> spin()
      rollers = Map.get(data, :rollers)

      if Map.has_key?(history, rollers),
        do: IO.inspect({n, score(data), Map.get(history, rollers)})

      data |> Map.put(:history, history |> Map.put(rollers, {n, score(data)}))
    end)
  end

  defp score(%{y_max: y_max, rollers: rollers}),
    do: rollers |> Enum.map(fn {_, y} -> y_max + 1 - y end) |> Enum.sum()

  defp parse(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.reject(&(&1 == ""))
    |> Enum.with_index()
    |> Enum.reduce(
      %{y_max: 0, x_max: 0, blocks_by_row: %{}, blocks_by_column: %{}, rollers: []},
      fn {row, y}, %{blocks_by_row: blocks_by_row} = acc ->
        acc =
          acc |> Map.put(:y_max, y) |> Map.put(:blocks_by_row, blocks_by_row |> Map.put(y, []))

        row
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.reduce(acc, fn {c, x},
                               %{
                                 x_max: x_max,
                                 blocks_by_row: blocks_by_row,
                                 blocks_by_column: blocks_by_column,
                                 rollers: rollers
                               } = acc ->
          acc = acc |> Map.put(:x_max, max(x, x_max))

          case c do
            ?. ->
              acc

            ?# ->
              acc
              |> Map.put(
                :blocks_by_row,
                blocks_by_row |> Map.put(y, [x | Map.get(blocks_by_row, y)])
              )
              |> Map.put(
                :blocks_by_column,
                blocks_by_column |> Map.put(x, [y | Map.get(blocks_by_column, x, [])])
              )

            ?O ->
              acc |> Map.put(:rollers, [{x, y} | rollers])
          end
        end)
      end
    )
  end

  defp with_vertical_ranges(
         %{x_max: x_max, y_max: y_max, blocks_by_column: blocks_by_column} = data
       ) do
    ranges =
      blocks_by_column
      |> Enum.map(fn {x, blocks} -> {x, find_ranges(y_max, blocks)} end)
      |> Enum.into(%{})

    default_ranges =
      for x <- 0..x_max, into: %{} do
        {x, [0..y_max]}
      end

    data
    |> Map.put(
      :vertical_ranges,
      Map.merge(default_ranges, ranges)
    )
  end

  defp with_horizontal_ranges(%{x_max: x_max, y_max: y_max, blocks_by_row: blocks_by_row} = data) do
    ranges =
      blocks_by_row
      |> Enum.map(fn {y, blocks} -> {y, find_ranges(x_max, blocks)} end)
      |> Enum.into(%{})

    default_ranges =
      for y <- 0..y_max, into: %{} do
        {y, [0..x_max]}
      end

    data
    |> Map.put(
      :horizontal_ranges,
      Map.merge(default_ranges, ranges)
    )
  end

  defp find_ranges(last, blocks),
    do:
      blocks
      |> Enum.sort()
      |> then(fn list -> [-1 | list] ++ [last + 1] end)
      |> Enum.map(fn x -> [x - 1, x + 1] end)
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [[_, a], [b, _]] -> a..b//1 end)
      |> Enum.reject(fn r -> Range.size(r) == 0 end)

  defp tilt_north(
         %{
           vertical_ranges: vertical_ranges,
           rollers: rollers
         } = data
       ) do
    rollers = rollers |> Enum.group_by(fn {x, _} -> x end, fn {_, y} -> y end)

    rollers =
      vertical_ranges
      |> Enum.flat_map(fn {x, ranges} ->
        ranges
        |> Enum.flat_map(fn range ->
          rollers
          |> Map.get(x, [])
          |> Enum.count(fn y -> y in range end)
          |> then(fn n -> Enum.take(range, n) end)
          |> Enum.map(fn y -> {x, y} end)
        end)
      end)

    %{data | rollers: rollers}
  end

  defp tilt_south(
         %{
           vertical_ranges: vertical_ranges,
           rollers: rollers
         } = data
       ) do
    rollers = rollers |> Enum.group_by(fn {x, _} -> x end, fn {_, y} -> y end)

    rollers =
      vertical_ranges
      |> Enum.flat_map(fn {x, ranges} ->
        ranges
        |> Enum.flat_map(fn range ->
          rollers
          |> Map.get(x, [])
          |> Enum.count(fn y -> y in range end)
          |> then(fn n -> range |> Enum.reverse() |> Enum.take(n) end)
          |> Enum.map(fn y -> {x, y} end)
        end)
      end)

    %{data | rollers: rollers}
  end

  defp tilt_west(
         %{
           horizontal_ranges: horizontal_ranges,
           rollers: rollers
         } = data
       ) do
    rollers = rollers |> Enum.group_by(fn {_, y} -> y end, fn {x, _} -> x end)

    rollers =
      horizontal_ranges
      |> Enum.flat_map(fn {y, ranges} ->
        ranges
        |> Enum.flat_map(fn range ->
          rollers
          |> Map.get(y, [])
          |> Enum.count(fn x -> x in range end)
          |> then(fn n -> Enum.take(range, n) end)
          |> Enum.map(fn x -> {x, y} end)
        end)
      end)

    %{data | rollers: rollers}
  end

  defp tilt_east(
         %{
           horizontal_ranges: horizontal_ranges,
           rollers: rollers
         } = data
       ) do
    rollers = rollers |> Enum.group_by(fn {_, y} -> y end, fn {x, _} -> x end)

    rollers =
      horizontal_ranges
      |> Enum.flat_map(fn {y, ranges} ->
        ranges
        |> Enum.flat_map(fn range ->
          rollers
          |> Map.get(y, [])
          |> Enum.count(fn x -> x in range end)
          |> then(fn n -> range |> Enum.reverse() |> Enum.take(n) end)
          |> Enum.map(fn x -> {x, y} end)
        end)
      end)

    %{data | rollers: rollers}
  end

  defp spin(data), do: data |> tilt_north() |> tilt_west() |> tilt_south() |> tilt_east()
end
