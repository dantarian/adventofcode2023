defmodule Sensor do
  @enforce_keys [:location, :range]
  defstruct [:location, :range]

  def new(loc_x, loc_y, beacon_x, beacon_y), do:
    %Sensor{location: {loc_x, loc_y}, range: AOCUtil.manhattan({loc_x, loc_y}, {beacon_x, beacon_y})}

  def range_x(%Sensor{location: {x, _}, range: range}), do: {x - range, x  + range}

  def range_for_row(%Sensor{location: {sx, sy}, range: range}, y), do: (sx - (range - abs(sy - y)))..(sx + (range - abs(sy - y)))//1

  def covered?(%Sensor{location: location, range: range}, point), do: AOCUtil.manhattan(location, point) <= range

  def any_cover?([], _), do: false
  def any_cover?([head | tail], point), do:
    if covered?(head, point), do: true, else: any_cover?(tail, point)
end

defmodule Day15 do
  def part1(file, row), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.map(fn [sx, sy, bx, by] -> {Sensor.new(sx, sy, bx, by), {bx, by}} end)
    |> covered_points(row)
    |> length()

  def part2(file, max_coord), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.map(fn [sx, sy, bx, by] -> {Sensor.new(sx, sy, bx, by), {bx, by}} end)
    |> uncovered_points(max_coord)
    |> hd()
    |> then(fn {x, y} -> x * 4_000_000 + y end)

  defp parse_line("Sensor at x=" <> rest_of_line), do:
    rest_of_line
    |> String.split("=")
    |> Enum.map(&Integer.parse/1)
    |> Enum.map(fn {x, _} -> x end)

  defp covered_points(sensors, row) do
    beacons = Enum.map(sensors, fn {_, b} -> b end) |> Enum.filter(fn {_, by} -> by == row end)
    sensors = Enum.map(sensors, fn {s, _} -> s end)
    {min_x, max_x} = sensors |> Enum.map(&Sensor.range_x/1) |> Enum.reduce({0,0}, fn {min, max}, {total_min, total_max} -> {min(total_min, min), max(total_max, max)} end)
    min_x..max_x
    |> Enum.filter(fn x -> Sensor.any_cover?(sensors, {x, row}) and {x, row} not in beacons end)
  end

  defp uncovered_points(sensors, max_coord) do
    beacons = Enum.map(sensors, fn {_, b} -> b end)
    sensors = Enum.map(sensors, fn {s, _} -> s end)
    0..max_coord
    |> Enum.flat_map(&uncovered_points(sensors, beacons, &1, max_coord))
  end

  defp uncovered_points(sensors, beacons, y, max_coord), do:
    do_uncovered_points(
      sensors |> Enum.map(&Sensor.range_for_row(&1, y)) |> Enum.sort_by(fn x -> x.first end), 
      beacons |> Enum.filter(fn {_, by} -> by == y end), 
      {0, y}, 
      max_coord, 
      []
    )

  defp do_uncovered_points([], _, _, _, points), do: points
  defp do_uncovered_points(_, _, {x, _}, max_coord, points) when x > max_coord, do: points
  defp do_uncovered_points([covered_range | other_ranges] = ranges, beacons, {x, y}, max_coord, points) do
    cond do
      x in covered_range -> do_uncovered_points(other_ranges, beacons, {covered_range.last + 1, y}, max_coord, points)
      x > covered_range.last -> do_uncovered_points(other_ranges, beacons, {x, y}, max_coord, points)
      x < covered_range.first and {x, y} in beacons -> do_uncovered_points(ranges, beacons, {x + 1, y}, max_coord, points)
      x < covered_range.first -> do_uncovered_points(ranges, beacons, {x + 1, y}, max_coord, [{x, y} | points])
    end
  end
end