defmodule Day2 do
  @rock 0
  @paper 1
  @scissors 2

  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.split(&1, " "))
      |> Enum.map(&translate/1)
      |> Enum.map(&score/1)
      |> Enum.sum()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.split(&1, " "))
      |> Enum.map(&translate2/1)
      |> Enum.map(&score/1)
      |> Enum.sum()

  defp translate([opponent, me]) do
    {case opponent do
       "A" -> @rock
       "B" -> @paper
       "C" -> @scissors
     end,
     case me do
       "X" -> @rock
       "Y" -> @paper
       "Z" -> @scissors
     end}
  end

  defp translate2([opponent, me]) do
    opp_move =
      case opponent do
        "A" -> @rock
        "B" -> @paper
        "C" -> @scissors
      end

    my_move =
      case me do
        "X" -> Integer.mod(opp_move - 1, 3)
        "Y" -> opp_move
        "Z" -> Integer.mod(opp_move + 1, 3)
      end

    {opp_move, my_move}
  end

  defp score({opponent, me}), do: me + 1 + Integer.mod(me - opponent + 1, 3) * 3
end
