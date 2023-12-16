defmodule Day16 do
  def part1(file),
    do: file |> parse() |> run() |> Enum.uniq_by(fn {location, _} -> location end) |> length()

  def part2(file) do
    map = file |> parse()
    x_max = map |> Map.keys() |> Enum.map(fn {x, _} -> x end) |> Enum.max()
    y_max = map |> Map.keys() |> Enum.map(fn {_, y} -> y end) |> Enum.max()

    max_from_top =
      for x <- 0..x_max do
        map |> run({x, 0}, :down) |> Enum.uniq_by(fn {location, _} -> location end) |> length()
      end
      |> Enum.max()

    max_from_bottom =
      for x <- 0..x_max do
        map |> run({x, y_max}, :up) |> Enum.uniq_by(fn {location, _} -> location end) |> length()
      end
      |> Enum.max()

    max_from_left =
      for y <- 0..y_max do
        map |> run({0, y}, :right) |> Enum.uniq_by(fn {location, _} -> location end) |> length()
      end
      |> Enum.max()

    max_from_right =
      for y <- 0..y_max do
        map
        |> run({x_max, y}, :left)
        |> Enum.uniq_by(fn {location, _} -> location end)
        |> length()
      end
      |> Enum.max()

    [max_from_top, max_from_bottom, max_from_left, max_from_right] |> Enum.max()
  end

  defp parse(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        line
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.map(fn {c, x} -> {{x, y}, c} end)
      end)
      |> Enum.into(%{})

  defp run(map, location \\ {0, 0}, direction \\ :right),
    do: do_run(map, {location, direction}, MapSet.new())

  defp do_run(map, {location, _}, trace) when not is_map_key(map, location), do: trace

  defp do_run(map, {location, direction}, trace) do
    if MapSet.member?(trace, {location, direction}) do
      trace
    else
      case(Map.get(map, location)) do
        ?- when direction == :up or direction == :down ->
          trace = do_run(map, {location, :left}, trace)
          do_run(map, {location, :right}, trace)

        ?| when direction == :left or direction == :right ->
          trace = do_run(map, {location, :up}, trace)
          do_run(map, {location, :down}, trace)

        _ ->
          do_run(map, next(map, location, direction), MapSet.put(trace, {location, direction}))
      end
    end
  end

  defp next(map, {x, y} = location, direction) do
    case Map.get(map, location) do
      ?/ when direction == :up -> {{x + 1, y}, :right}
      ?/ when direction == :down -> {{x - 1, y}, :left}
      ?/ when direction == :left -> {{x, y + 1}, :down}
      ?/ when direction == :right -> {{x, y - 1}, :up}
      ?\\ when direction == :up -> {{x - 1, y}, :left}
      ?\\ when direction == :down -> {{x + 1, y}, :right}
      ?\\ when direction == :left -> {{x, y - 1}, :up}
      ?\\ when direction == :right -> {{x, y + 1}, :down}
      _ when direction == :up -> {{x, y - 1}, :up}
      _ when direction == :down -> {{x, y + 1}, :down}
      _ when direction == :left -> {{x - 1, y}, :left}
      _ when direction == :right -> {{x + 1, y}, :right}
    end
  end
end
