defmodule Day8 do
  def part1(file) do
    [instructions, map | []] = AOCUtil.blocks!(file)
    instructions = instructions |> String.to_charlist() |> Stream.cycle()

    map =
      map
      |> String.split("\n")
      |> Enum.map(fn <<key::binary-size(3), " = (", left::binary-size(3), ", ",
                       right::binary-size(3), ")">> ->
        {key, {left, right}}
      end)
      |> Map.new()

    instructions
    |> Stream.transform("AAA", fn i, acc ->
      cond do
        acc == "ZZZ" -> {:halt, acc}
        i == ?L -> {[acc], map[acc] |> elem(0)}
        i == ?R -> {[acc], map[acc] |> elem(1)}
      end
    end)
    |> Enum.count()
  end

  def part2(file) do
    [instructions, map | []] = AOCUtil.blocks!(file)
    instructions = instructions |> String.to_charlist() |> Stream.cycle()

    map =
      map
      |> String.split("\n")
      |> Enum.map(fn <<key::binary-size(3), " = (", left::binary-size(3), ", ",
                       right::binary-size(3), ")">> ->
        {key, {left, right}}
      end)
      |> Map.new()

    starts = map |> Map.keys() |> Enum.filter(&String.ends_with?(&1, "A"))

    starts
    |> Enum.map(fn start ->
      instructions
      |> Stream.transform(start, fn i, acc ->
        cond do
          acc |> String.ends_with?("Z") -> {:halt, acc}
          i == ?L -> {[acc], map[acc] |> elem(0)}
          i == ?R -> {[acc], map[acc] |> elem(1)}
        end
      end)
      |> Enum.count()
    end)
    |> Enum.reduce(1, fn i, acc -> Math.lcm(i, acc) end)
  end
end
