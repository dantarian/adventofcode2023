defmodule Checked do
  use Agent

  def start_link(), do: Agent.start_link(fn -> %MapSet{} end, name: __MODULE__)

  def stop, do: Agent.stop(__MODULE__)

  def put(value), do: Agent.update(__MODULE__, fn state -> MapSet.put(state, value) end)

  def already_checked?(value),
    do: Agent.get(__MODULE__, fn state -> MapSet.member?(state, value) end)
end

defmodule Blizzards do
  defstruct [:height, :width, :repeat_rate, east: %{}, west: %{}, north: %{}, south: %{}]

  def new(height, width),
    do: %Blizzards{
      height: height,
      width: width,
      repeat_rate: div(height * width, Integer.gcd(height, width))
    }

  def add_blizzard(blizzards, x, y, :east),
    do: %Blizzards{
      blizzards
      | east: Map.put(blizzards.east, y, [x | Map.get(blizzards.east, y, [])])
    }

  def add_blizzard(blizzards, x, y, :west),
    do: %Blizzards{
      blizzards
      | west: Map.put(blizzards.west, y, [x | Map.get(blizzards.west, y, [])])
    }

  def add_blizzard(blizzards, x, y, :north),
    do: %Blizzards{
      blizzards
      | north: Map.put(blizzards.north, x, [y | Map.get(blizzards.north, x, [])])
    }

  def add_blizzard(blizzards, x, y, :south),
    do: %Blizzards{
      blizzards
      | south: Map.put(blizzards.south, x, [y | Map.get(blizzards.south, x, [])])
    }

  def empty?(blizzards, {x, y, t}) do
    cond do
      Cache.has_key?({x, y, t}) ->
        Cache.get({x, y, t})

      true ->
        xe = Integer.mod(x - t, blizzards.width)
        xw = Integer.mod(x + t, blizzards.width)
        yn = Integer.mod(y + t, blizzards.height)
        ys = Integer.mod(y - t, blizzards.height)

        result =
          Map.get(blizzards.east, y, []) |> Enum.all?(fn b -> b != xe end) &&
            Map.get(blizzards.west, y, []) |> Enum.all?(fn b -> b != xw end) &&
            Map.get(blizzards.north, x, []) |> Enum.all?(fn b -> b != yn end) &&
            Map.get(blizzards.south, x, []) |> Enum.all?(fn b -> b != ys end)

        Cache.put({x, y, t}, result)
        result
    end
  end
end

defmodule Day24 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> quickest_path()

  def part2(file),
    do:
      file
      |> File.read!()
      |> parse()
      |> quickest_path_there_back_and_back_there()

  defp parse(str) do
    lines =
      str
      |> String.split("\n")

    height = length(lines) - 2
    width = byte_size(hd(lines)) - 2

    lines
    |> Enum.with_index(-1)
    |> Enum.reduce(Blizzards.new(height, width), fn {line, y}, acc ->
      line
      |> String.to_charlist()
      |> Enum.with_index(-1)
      |> Enum.reduce(acc, fn {char, x}, acc ->
        case char do
          ?> -> Blizzards.add_blizzard(acc, x, y, :east)
          ?< -> Blizzards.add_blizzard(acc, x, y, :west)
          ?^ -> Blizzards.add_blizzard(acc, x, y, :north)
          ?v -> Blizzards.add_blizzard(acc, x, y, :south)
          _ -> acc
        end
      end)
    end)
  end

  defp quickest_path(blizzards) do
    BestResult.start_link(8 * AOCUtil.manhattan({0, -1}, {blizzards.width, blizzards.height}))
    Cache.start_link()
    Checked.start_link()
    find_quickest_path(blizzards, [{0, -1, 0}], {blizzards.width - 1, blizzards.height - 1}, 0)
    result = BestResult.value()
    BestResult.stop()
    Cache.stop()
    Checked.stop()
    result
  end

  defp quickest_path_there_back_and_back_there(blizzards) do
    BestResult.start_link(8 * AOCUtil.manhattan({0, -1}, {blizzards.width, blizzards.height}))
    Cache.start_link()
    Checked.start_link()
    find_quickest_path(blizzards, [{0, -1, 0}], {blizzards.width - 1, blizzards.height - 1}, 0)
    result = BestResult.value()
    BestResult.stop()
    Cache.stop()
    Checked.stop()

    BestResult.start_link(
      result + 8 * AOCUtil.manhattan({0, -1}, {blizzards.width, blizzards.height})
    )

    Cache.start_link()
    Checked.start_link()

    find_quickest_path(
      blizzards,
      [{blizzards.width - 1, blizzards.height, result}],
      {0, 0},
      result
    )

    result = BestResult.value()
    BestResult.stop()
    Cache.stop()
    Checked.stop()

    BestResult.start_link(
      result + 8 * AOCUtil.manhattan({0, -1}, {blizzards.width, blizzards.height})
    )

    Cache.start_link()
    Checked.start_link()

    find_quickest_path(
      blizzards,
      [{0, -1, result}],
      {blizzards.width - 1, blizzards.height - 1},
      result
    )

    result = BestResult.value()
    BestResult.stop()
    Cache.stop()
    Checked.stop()

    result
  end

  defp find_quickest_path(_, [], _, _), do: nil

  defp find_quickest_path(blizzards, [{x, y, t} | rest], {targetx, targety} = target, start_time) do
    cond do
      Checked.already_checked?({x, y, t}) ->
        find_quickest_path(blizzards, rest, target, start_time)

      t + AOCUtil.manhattan({x, y}, {targetx, targety}) >= BestResult.value() ->
        Checked.put({x, y, t})
        find_quickest_path(blizzards, rest, target, start_time)

      {x, y} == {targetx, targety} ->
        Checked.put({x, y, t})
        BestResult.put_if_lesser(t + 1)
        find_quickest_path(blizzards, rest, target, start_time)

      true ->
        Checked.put({x, y, t})

        find_quickest_path(
          blizzards,
          options(blizzards, {x, y, t}, target, start_time) ++ rest,
          target,
          start_time
        )
    end
  end

  defp options(blizzards, {x, y, t}, target, start_time) do
    {startx, starty} =
      if target == {0, 0},
        do: {blizzards.width - 1, blizzards.height},
        else: {0, -1}

    [{x + 1, y, t + 1}, {x, y + 1, t + 1}, {x - 1, y, t + 1}, {x, y - 1, t + 1}, {x, y, t + 1}]
    |> Enum.reject(fn
      {^startx, ^starty, _} ->
        {x, y} != {startx, starty} or t > start_time + blizzards.repeat_rate

      {x, y, _} when x in 0..(blizzards.width - 1) and y in 0..(blizzards.height - 1) ->
        false

      _ ->
        true
    end)
    |> Enum.filter(&Blizzards.empty?(blizzards, &1))
  end
end
