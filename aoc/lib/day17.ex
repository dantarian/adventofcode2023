defmodule Day17 do
  def part1(file) do
    {data, endpoint} = file |> parse()
    cheapest_path(data, &find_neighbours/3, fn position, _ -> position == endpoint end)
  end

  def part2(file) do
    {data, endpoint} = file |> parse()

    cheapest_path(data, &find_ultra_neighbours/3, fn position, distance ->
      position == endpoint and distance >= 4
    end)
  end

  defp parse(file) do
    lines = file |> AOCUtil.lines!()
    max_y = (lines |> length()) - 1
    max_x = (lines |> hd() |> String.length()) - 1

    data =
      lines
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, y} ->
        line
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.map(fn {c, x} ->
          {{x, y}, c - ?0}
        end)
      end)
      |> Map.new()

    {data, {max_x, max_y}}
  end

  defp cheapest_path(data, neighbours_fun, completion_fun) do
    do_cheapest_path(
      Heap.new(fn {c1, p1, _, _}, {c2, p2, _, _} -> c1 < c2 or (c1 == c2 and p1 > p2) end)
      |> Heap.push({data |> Map.get({0, 1}), {0, 1}, :down, 1})
      |> Heap.push({data |> Map.get({1, 0}), {1, 0}, :right, 1}),
      data,
      MapSet.new(),
      neighbours_fun,
      completion_fun
    )
  end

  defp do_cheapest_path(nodes, data, visited, neighbours_fun, completion_fun) do
    {{cost, position, direction, distance}, rest} = nodes |> Heap.split()
    # IO.inspect({cost, position, direction, distance})

    cond do
      completion_fun.(position, distance) ->
        cost

      MapSet.member?(visited, {position, direction, distance}) ->
        do_cheapest_path(rest, data, visited, neighbours_fun, completion_fun)

      true ->
        neighbours_fun.(position, direction, distance)
        |> Enum.filter(fn {n_location, _, _} -> data |> Map.has_key?(n_location) end)
        |> Enum.reject(&MapSet.member?(visited, &1))
        |> Enum.reduce(rest, fn {n_location, n_direction, n_distance}, acc ->
          acc
          |> Heap.push(
            {cost + (data |> Map.get(n_location)), n_location, n_direction, n_distance}
          )
        end)
        |> then(
          &do_cheapest_path(
            &1,
            data,
            visited |> MapSet.put({position, direction, distance}),
            neighbours_fun,
            completion_fun
          )
        )
    end
  end

  defp find_neighbours({x, y}, :right, steps) when steps > 2,
    do: [{{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_neighbours({x, y}, :right, steps),
    do: [{{x, y + 1}, :down, 1}, {{x + 1, y}, :right, steps + 1}, {{x, y - 1}, :up, 1}]

  defp find_neighbours({x, y}, :left, steps) when steps > 2,
    do: [{{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_neighbours({x, y}, :left, steps),
    do: [{{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}, {{x - 1, y}, :left, steps + 1}]

  defp find_neighbours({x, y}, :up, steps) when steps > 2,
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]

  defp find_neighbours({x, y}, :up, steps),
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}, {{x, y - 1}, :up, steps + 1}]

  defp find_neighbours({x, y}, :down, steps) when steps > 2,
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]

  defp find_neighbours({x, y}, :down, steps),
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}, {{x, y + 1}, :down, steps + 1}]

  defp find_ultra_neighbours({x, y}, :right, steps) when steps < 4,
    do: [{{x + 1, y}, :right, steps + 1}]

  defp find_ultra_neighbours({x, y}, :right, steps) when steps < 10,
    do: [{{x + 1, y}, :right, steps + 1}, {{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_ultra_neighbours({x, y}, :right, _),
    do: [{{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_ultra_neighbours({x, y}, :left, steps) when steps < 4,
    do: [{{x - 1, y}, :left, steps + 1}]

  defp find_ultra_neighbours({x, y}, :left, steps) when steps < 10,
    do: [{{x - 1, y}, :left, steps + 1}, {{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_ultra_neighbours({x, y}, :left, _),
    do: [{{x, y + 1}, :down, 1}, {{x, y - 1}, :up, 1}]

  defp find_ultra_neighbours({x, y}, :down, steps) when steps < 4,
    do: [{{x, y + 1}, :down, steps + 1}]

  defp find_ultra_neighbours({x, y}, :down, steps) when steps < 10,
    do: [{{x, y + 1}, :down, steps + 1}, {{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]

  defp find_ultra_neighbours({x, y}, :down, _),
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]

  defp find_ultra_neighbours({x, y}, :up, steps) when steps < 4,
    do: [{{x, y - 1}, :up, steps + 1}]

  defp find_ultra_neighbours({x, y}, :up, steps) when steps < 10,
    do: [{{x, y - 1}, :up, steps + 1}, {{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]

  defp find_ultra_neighbours({x, y}, :up, _),
    do: [{{x + 1, y}, :right, 1}, {{x - 1, y}, :left, 1}]
end
