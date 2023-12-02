defmodule CubeGameTurn do
  defstruct red: 0, green: 0, blue: 0

  def parse(turn) do
    turn
    |> String.split(", ")
    |> Enum.map(&String.split(&1, " ", parts: 2))
    |> Enum.reduce(%CubeGameTurn{}, fn [count | [colour | []]], acc ->
      case colour do
        "red" -> %{acc | red: String.to_integer(count)}
        "green" -> %{acc | green: String.to_integer(count)}
        "blue" -> %{acc | blue: String.to_integer(count)}
      end
    end)
  end

  def valid?(turn, red, green, blue) do
    turn.red <= red && turn.green <= green && turn.blue <= blue
  end
end

defmodule CubeGame do
  defstruct id: 0, turns: []

  def parse(line) do
    [game_spec | [turns | []]] = String.split(line, ": ", parts: 2)
    [_ | [id | []]] = String.split(game_spec, " ", parts: 2)

    %CubeGame{
      id: String.to_integer(id),
      turns: String.split(turns, "; ") |> Enum.map(&CubeGameTurn.parse(&1))
    }
  end

  def valid?(%CubeGame{turns: turns}, red, green, blue) do
    turns |> Enum.all?(&CubeGameTurn.valid?(&1, red, green, blue))
  end

  def min_viable_power(%CubeGame{turns: turns}) do
    turns
    |> Enum.reduce(%CubeGameTurn{}, fn %CubeGameTurn{red: r, green: g, blue: b}, acc ->
      %{acc | red: max(r, acc.red), green: max(g, acc.green), blue: max(b, acc.blue)}
    end)
    |> then(fn %CubeGameTurn{red: red, green: green, blue: blue} -> red * green * blue end)
  end
end

defmodule Day2 do
  def part1(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(&CubeGame.parse(&1))
    |> Enum.filter(&CubeGame.valid?(&1, 12, 13, 14))
    |> Enum.map(fn x -> x.id end)
    |> Enum.sum()
  end

  def part2(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(&CubeGame.parse(&1))
    |> Enum.map(&CubeGame.min_viable_power(&1))
    |> Enum.sum()
  end
end
