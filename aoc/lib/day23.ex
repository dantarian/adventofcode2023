defmodule Day23 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> move(:north, 10)
      |> empty_area()

  def part2(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> move_until_done(:north)

  defp parse(str),
    do:
      str
      |> String.split("\n")
      |> Enum.with_index()
      |> Enum.reduce(%MapSet{}, fn {line, y}, mapset ->
        line
        |> String.to_charlist()
        |> Enum.with_index()
        |> Enum.reduce(mapset, fn {c, x}, mapset ->
          if c == ?#, do: MapSet.put(mapset, {x, y}), else: mapset
        end)
      end)

  defp neighbours({x, y}),
    do: [
      {x - 1, y - 1},
      {x, y - 1},
      {x + 1, y - 1},
      {x - 1, y},
      {x + 1, y},
      {x - 1, y + 1},
      {x, y + 1},
      {x + 1, y + 1}
    ]

  defp move(elves, _, 0), do: elves

  defp move(elves, direction, turns_remaining), 
    do: move(do_move(elves, direction), next_direction(direction), turns_remaining - 1)

  def move_until_done(elves, direction, turns_taken \\ 1) do
    new_elves = do_move(elves, direction)
    if MapSet.equal?(elves, new_elves), 
      do: turns_taken, 
      else: move_until_done(new_elves, next_direction(direction), turns_taken + 1)
  end

  defp do_move(elves, direction) do
    {might_move, wont_move} =
      elves
      |> Enum.split_with(fn elf ->
        elf
        |> neighbours()
        |> Enum.any?(&MapSet.member?(elves, &1))
      end)

    might_move
    |> Enum.reduce(%{}, fn elf, proposed_moves ->
      proposed_moves
      |> Map.update(pick_move(elf, elves, direction), [elf], fn others -> [elf | others] end)
    end)
    |> Map.to_list()
    |> Enum.reduce(MapSet.new(wont_move), fn {target, elves}, new_elves ->
      if length(elves) == 1,
        do: MapSet.put(new_elves, target),
        else: Enum.reduce(elves, new_elves, fn elf, new_elves -> MapSet.put(new_elves, elf) end)
    end)
  end

  defp next_direction(:north), do: :south
  defp next_direction(:south), do: :west
  defp next_direction(:west), do: :east
  defp next_direction(:east), do: :north

  defp pick_move({x, y} = elf, elves, :north) do
    cond do
      can_move_north?(elf, elves) -> {x, y - 1}
      can_move_south?(elf, elves) -> {x, y + 1}
      can_move_west?(elf, elves) -> {x - 1, y}
      can_move_east?(elf, elves) -> {x + 1, y}
      true -> elf
    end
  end

  defp pick_move({x, y} = elf, elves, :south) do
    cond do
      can_move_south?(elf, elves) -> {x, y + 1}
      can_move_west?(elf, elves) -> {x - 1, y}
      can_move_east?(elf, elves) -> {x + 1, y}
      can_move_north?(elf, elves) -> {x, y - 1}
      true -> elf
    end
  end

  defp pick_move({x, y} = elf, elves, :west) do
    cond do
      can_move_west?(elf, elves) -> {x - 1, y}
      can_move_east?(elf, elves) -> {x + 1, y}
      can_move_north?(elf, elves) -> {x, y - 1}
      can_move_south?(elf, elves) -> {x, y + 1}
      true -> elf
    end
  end

  defp pick_move({x, y} = elf, elves, :east) do
    cond do
      can_move_east?(elf, elves) -> {x + 1, y}
      can_move_north?(elf, elves) -> {x, y - 1}
      can_move_south?(elf, elves) -> {x, y + 1}
      can_move_west?(elf, elves) -> {x - 1, y}
      true -> elf
    end
  end

  defp can_move_north?({x, y}, elves), do:
    !MapSet.member?(elves, {x - 1, y - 1}) and 
    !MapSet.member?(elves, {x, y - 1}) and
    !MapSet.member?(elves, {x + 1, y - 1})

  defp can_move_south?({x, y}, elves), do:
    !MapSet.member?(elves, {x - 1, y + 1}) and 
    !MapSet.member?(elves, {x, y + 1}) and
    !MapSet.member?(elves, {x + 1, y + 1})

  defp can_move_west?({x, y}, elves), do:
    !MapSet.member?(elves, {x - 1, y - 1}) and 
    !MapSet.member?(elves, {x - 1, y}) and
    !MapSet.member?(elves, {x - 1, y + 1})

  defp can_move_east?({x, y}, elves), do:
    !MapSet.member?(elves, {x + 1, y - 1}) and 
    !MapSet.member?(elves, {x + 1, y}) and
    !MapSet.member?(elves, {x + 1, y + 1})

  defp empty_area(elves) do
    {{minx, _}, {maxx, _}} = Enum.min_max_by(elves, fn {x, _} -> x end)
    {{_, miny}, {_, maxy}} = Enum.min_max_by(elves, fn {_, y} -> y end)

    (1 + maxx - minx) * (1 + maxy - miny) - length(MapSet.to_list(elves))
  end
end
