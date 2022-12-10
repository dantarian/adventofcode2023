defmodule Day5 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n\n")
      |> then(&parse/1)
      |> then(&apply_moves/1)
      |> then(&read_tops/1)

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n\n")
      |> then(&parse/1)
      |> then(&apply_moves_without_reordering/1)
      |> then(&read_tops/1)

  defp parse([state, moves]), do: [parse_initial_state(state), parse_moves(moves)]

  defp parse_initial_state(state),
    do: do_parse_initial_state(state |> String.split("\n") |> Enum.reverse())

  defp do_parse_initial_state([stacks_def | state_def]) do
    num_stacks = stacks_def |> String.split() |> List.last() |> String.to_integer()
    stacks = Map.new(1..num_stacks, fn x -> {x, []} end)
    do_parse_state(state_def, stacks)
  end

  defp do_parse_state([], stacks), do: stacks

  defp do_parse_state([head | tail], stacks) do
    crates = head |> String.to_charlist() |> Enum.chunk_every(4) |> Enum.map(&hd(tl(&1)))

    do_parse_state(
      tail,
      Enum.with_index(crates, 1)
      |> Enum.reduce(stacks, fn {element, index}, acc ->
        case element do
          ?\s -> acc
          c -> %{acc | index => [c | acc[index]]}
        end
      end)
    )
  end

  defp parse_moves(moves), do: do_parse_moves(String.split(moves, "\n"), [])

  defp do_parse_moves([], moves), do: Enum.reverse(moves)

  defp do_parse_moves([head | tail], moves),
    do:
      do_parse_moves(tail, [
        head |> String.split() |> tl |> Enum.take_every(2) |> Enum.map(&String.to_integer/1)
        | moves
      ])

  defp apply_moves([state, moves]), do: do_apply_moves(state, moves)
  defp do_apply_moves(state, []), do: state

  defp do_apply_moves(state, [[count, from, to] | other_moves]),
    do: do_apply_moves(do_apply_move(state, from, to, count), other_moves)

  defp do_apply_move(state, _, _, 0), do: state

  defp do_apply_move(state, from, to, count),
    do:
      do_apply_move(
        %{state | to => [hd(state[from]) | state[to]], from => tl(state[from])},
        from,
        to,
        count - 1
      )

  defp apply_moves_without_reordering([state, moves]),
    do: do_apply_moves_without_reordering(state, moves)

  defp do_apply_moves_without_reordering(state, []), do: state

  defp do_apply_moves_without_reordering(state, [[count, from, to] | other_moves]),
    do:
      do_apply_moves_without_reordering(
        %{
          state
          | to => Enum.take(state[from], count) ++ state[to],
            from => Enum.drop(state[from], count)
        },
        other_moves
      )

  defp read_tops(state) do
    Enum.map(1..map_size(state), fn x -> hd(state[x]) end)
  end
end
