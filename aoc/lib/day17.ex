defmodule RockDispenser do
  defstruct [:rocks, :moves, :rocks_length, :moves_length, rocks_dispensed: 0, moves_dispensed: 0]
  use Agent

  def start_link(rocks, moves),
    do:
      Agent.start_link(
        fn ->
          %RockDispenser{
            rocks: Qex.new(rocks),
            moves: Qex.new(moves),
            rocks_length: length(rocks),
            moves_length: length(moves)
          }
        end,
        name: __MODULE__
      )

  def stop, do: Agent.stop(__MODULE__)

  def peek_move, do: Agent.get(__MODULE__, fn state -> Qex.first!(state.moves) end)

  # This is for part 2 - I used it experimentally to find the cycle length.
  def check_cycle do
    {rocks_dispensed, rocks_length, moves_dispensed, moves_length} =
      Agent.get(__MODULE__, fn state ->
        {
          state.rocks_dispensed,
          state.rocks_length,
          state.moves_dispensed,
          state.moves_length
        }
      end)

    if Integer.mod(rocks_dispensed, rocks_length) == 1 and
         Integer.mod(moves_dispensed, moves_length) == 0,
       do: IO.puts(rocks_dispensed)
  end

  def next_move do
    check_cycle()

    Agent.get_and_update(__MODULE__, fn state ->
      {move, moves} = Qex.pop!(state.moves)

      {move,
       %RockDispenser{
         state
         | moves: moves |> Qex.push(move),
           moves_dispensed: state.moves_dispensed + 1
       }}
    end)
  end

  def next_rock do
    check_cycle()

    Agent.get_and_update(__MODULE__, fn state ->
      {rock, rocks} = Qex.pop!(state.rocks)

      {rock,
       %RockDispenser{
         state
         | rocks: rocks |> Qex.push(rock),
           rocks_dispensed: state.rocks_dispensed + 1
       }}
    end)
  end

  def rocks_dropped, do: Agent.get(__MODULE__, fn state -> state.rocks_dispensed end)
end

defmodule Day17 do
  import Bitwise
  require Integer
  @rocks [[30], [8, 28, 8], [28, 4, 4], [16, 16, 16, 16], [24, 24]]

  def part1(file, rock_count),
    do:
      file
      |> File.read!()
      |> drop_rocks(rock_count)

  defp drop_rocks(movements, rocks_to_drop) do
    RockDispenser.start_link(@rocks, String.to_charlist(movements))
    result = do_drop_rocks([127], rocks_to_drop)
    RockDispenser.stop()
    result
  end

  defp do_drop_rocks(fallen, 0) do
    # print(fallen)
    length(fallen) - 1
  end

  defp do_drop_rocks(fallen, remaining) do
    RockDispenser.next_rock()
    |> free_move_rock(4)
    |> drop_rock(fallen)
    |> do_drop_rocks(remaining - 1)
  end

  defp free_move_rock(rock, 0), do: rock

  defp free_move_rock(rock, times),
    do:
      rock
      |> shift(RockDispenser.next_move())
      |> free_move_rock(times - 1)

  defp shift(rock, ?<),
    do:
      if(rock |> Enum.all?(&(&1 < 64)),
        do: rock |> Enum.map(&(&1 <<< 1)),
        else: rock
      )

  defp shift(rock, ?>),
    do:
      if(rock |> Enum.all?(&Integer.is_even/1),
        do: rock |> Enum.map(&(&1 >>> 1)),
        else: rock
      )

  defp can_move?(rock, fallen_chunk),
    do: Enum.zip_with(rock, fallen_chunk, fn a, b -> (a &&& b) == 0 end) |> Enum.all?()

  defp drop_rock(rock, [top_fallen | remaining_fallen]),
    do: do_drop_rock(rock, [top_fallen], remaining_fallen)

  defp do_drop_rock(rock, fallen_chunk, remaining_fallen) do
    cond do
      !can_move?(rock, fallen_chunk) ->
        (merge(rock, tl(fallen_chunk)) |> Enum.reverse()) ++
          [hd(fallen_chunk)] ++ remaining_fallen

      can_move?(shift(rock, RockDispenser.peek_move()), fallen_chunk) ->
        do_drop_rock(
          shift(rock, RockDispenser.next_move()),
          [hd(remaining_fallen) | fallen_chunk],
          tl(remaining_fallen)
        )

      RockDispenser.next_move() ->
        do_drop_rock(rock, [hd(remaining_fallen) | fallen_chunk], tl(remaining_fallen))
    end
  end

  defp merge(rock, fallen_chunk) when length(rock) == length(fallen_chunk),
    do: Enum.zip_with(rock, fallen_chunk, fn a, b -> a ||| b end)

  defp merge(rock, fallen_chunk) when length(rock) > length(fallen_chunk),
    do:
      merge(rock |> Enum.take(length(fallen_chunk)), fallen_chunk) ++
        (rock |> Enum.drop(length(fallen_chunk)))

  defp merge(rock, fallen_chunk) when length(rock) < length(fallen_chunk),
    do:
      merge(rock, fallen_chunk |> Enum.take(length(rock))) ++
        (fallen_chunk |> Enum.drop(length(rock)))

  # defp print(fallen), do:
  #   fallen
  #     |> Enum.with_index(fn val, idx -> {val, length(fallen) - idx} end)
  #     |> Enum.each(fn {val, idx} -> val 
  #     |> Integer.to_string(2) 
  #     |> String.pad_leading(7)
  #     |> String.replace("1", "#")
  #     |> String.replace("0", " ")
  #     |> Kernel.<>(" " <> Integer.to_string(idx))
  #     |> IO.puts end)
end
