defmodule Day9 do
  def part1(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.split/1)
    |> Enum.map(fn [a, b] -> {a, String.to_integer(b)} end)
    |> chase()
    |> MapSet.size()

  def part2(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&String.split/1)
    |> Enum.map(fn [a, b] -> {a, String.to_integer(b)} end)
    |> long_chase()
    |> MapSet.size()

  defp chase(commands), do: do_chase(MapSet.new(), {0,0}, {0,0}, commands)

  defp do_chase(results, _, _, []), do: results
  defp do_chase(results, head, tail, [{_, 0} | other_commands]), do: do_chase(results, head, tail, other_commands)
  defp do_chase(results, head, tail, [{direction, distance} | other_commands]) do
    head = move_head(head, direction)
    tail = move_tail(tail, head)
    do_chase(MapSet.put(results, tail), head, tail, [{direction, distance - 1} | other_commands])
  end

  defp long_chase(commands), do: do_long_chase(MapSet.new(), Enum.map(1..10, fn _ -> {0, 0} end), commands)

  defp do_long_chase(results, _, []), do: results
  defp do_long_chase(results, knots, [{_, 0} | other_commands]), do: do_long_chase(results, knots, other_commands)
  defp do_long_chase(results, [head | knots], [{direction, distance} | other_commands]) do
    head = move_head(head, direction)
    knots = Enum.scan(knots, head, &move_tail/2)
    do_long_chase(MapSet.put(results, List.last(knots)), [head | knots], [{direction, distance - 1} | other_commands])
  end

  defp move_head({x, y}, "R"), do: {x - 1, y}
  defp move_head({x, y}, "L"), do: {x + 1, y}
  defp move_head({x, y}, "U"), do: {x, y + 1}
  defp move_head({x, y}, "D"), do: {x, y - 1}

  defp move_tail({tx, ty}, {hx, hy}) when abs(tx - hx) <= 1 and abs(ty - hy) <= 1, do: {tx, ty}
  defp move_tail({tx, ty}, {hx, hy}) when hx == tx and hy > ty, do: {tx, ty + 1}
  defp move_tail({tx, ty}, {hx, hy}) when hx == tx and hy < ty, do: {tx, ty - 1}
  defp move_tail({tx, ty}, {hx, hy}) when hx > tx and hy == ty, do: {tx + 1, ty}
  defp move_tail({tx, ty}, {hx, hy}) when hx < tx and hy == ty, do: {tx - 1, ty}
  defp move_tail({tx, ty}, {hx, hy}) when hx > tx and hy > ty, do: {tx + 1, ty + 1}
  defp move_tail({tx, ty}, {hx, hy}) when hx > tx and hy < ty, do: {tx + 1, ty - 1}
  defp move_tail({tx, ty}, {hx, hy}) when hx < tx and hy < ty, do: {tx - 1, ty - 1}
  defp move_tail({tx, ty}, {hx, hy}) when hx < tx and hy > ty, do: {tx - 1, ty + 1}
end
