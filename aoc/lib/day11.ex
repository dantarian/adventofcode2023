defmodule Monkey do
  defstruct [:items, :operation, :divisor, :true_destination, :false_destination, inspected: 0]
end

defmodule Multimod do
  defstruct [
    :value,
    mods: %{2 => 0, 3 => 0, 5 => 0, 7 => 0, 11 => 0, 13 => 0, 17 => 0, 19 => 0, 23 => 0}
  ]

  def new(val), do: Multimod.add(%Multimod{}, val)
  def new_with_val(val), do: Multimod.add(%Multimod{value: 0}, val)

  def new_list(list), do: Enum.map(list, &Multimod.new/1)
  def new_list_with_val(list), do: Enum.map(list, &Multimod.new_with_val/1)

  def add(%Multimod{value: nil, mods: mods}, val),
    do: %Multimod{
      value: nil,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v + val, k)} end)
    }

  def add(%Multimod{value: value, mods: mods}, val),
    do: %Multimod{
      value: value + val,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v + val, k)} end)
    }

  def multiply(%Multimod{value: nil, mods: mods}, val),
    do: %Multimod{
      value: nil,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v * val, k)} end)
    }

  def multiply(%Multimod{value: value, mods: mods}, val),
    do: %Multimod{
      value: value * val,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v * val, k)} end)
    }

  def square(%Multimod{value: nil, mods: mods}),
    do: %Multimod{
      value: nil,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v * v, k)} end)
    }

  def square(%Multimod{value: value, mods: mods}),
    do: %Multimod{
      value: value * value,
      mods: Enum.reduce(mods, mods, fn {k, v}, acc -> %{acc | k => Integer.mod(v * v, k)} end)
    }

  def divide(%Multimod{} = mm, 1), do: mm

  def divide(%Multimod{value: value, mods: mods}, val),
    do: %Multimod{
      value: div(value, val),
      mods:
        Enum.reduce(mods, mods, fn {k, _}, acc ->
          %{acc | k => Integer.mod(div(value, val), k)}
        end)
    }

  def divisible_by(%Multimod{mods: mods}, val), do: Map.get(mods, val) == 0
end

defmodule Day11 do
  def part1,
    do:
      initialise_monkeys()
      |> play_catch(3, 20)
      |> Map.values()
      |> Enum.map(fn monkey -> monkey.inspected end)
      |> Enum.sort(:desc)
      |> Enum.take(2)
      |> Enum.product()

  def part2,
    do:
      initialise_monkeys()
      |> play_catch(1, 10_000)
      |> Map.values()
      |> Enum.map(fn monkey -> monkey.inspected end)
      |> Enum.sort(:desc)
      |> Enum.take(2)
      |> Enum.product()

  def initialise_monkeys(),
    do: %{
      0 => %Monkey{
        items: [96, 60, 68, 91, 83, 57, 85],
        operation: fn x -> Multimod.multiply(x, 2) end,
        divisor: 17,
        true_destination: 2,
        false_destination: 5
      },
      1 => %Monkey{
        items: [75, 78, 68, 81, 73, 99],
        operation: fn x -> Multimod.add(x, 3) end,
        divisor: 13,
        true_destination: 7,
        false_destination: 4
      },
      2 => %Monkey{
        items: [69, 86, 67, 55, 96, 69, 94, 85],
        operation: fn x -> Multimod.add(x, 6) end,
        divisor: 19,
        true_destination: 6,
        false_destination: 5
      },
      3 => %Monkey{
        items: [88, 75, 74, 98, 80],
        operation: fn x -> Multimod.add(x, 5) end,
        divisor: 7,
        true_destination: 7,
        false_destination: 1
      },
      4 => %Monkey{
        items: [82],
        operation: fn x -> Multimod.add(x, 8) end,
        divisor: 11,
        true_destination: 0,
        false_destination: 2
      },
      5 => %Monkey{
        items: [72, 92, 92],
        operation: fn x -> Multimod.multiply(x, 5) end,
        divisor: 3,
        true_destination: 6,
        false_destination: 3
      },
      6 => %Monkey{
        items: [74, 61],
        operation: fn x -> Multimod.square(x) end,
        divisor: 2,
        true_destination: 3,
        false_destination: 1
      },
      7 => %Monkey{
        items: [76, 86, 83, 55],
        operation: fn x -> Multimod.add(x, 4) end,
        divisor: 5,
        true_destination: 4,
        false_destination: 0
      }
    }

  def initialise_test_monkeys(),
    do: %{
      0 => %Monkey{
        items: [79, 98],
        operation: fn x -> Multimod.multiply(x, 19) end,
        divisor: 23,
        true_destination: 2,
        false_destination: 3
      },
      1 => %Monkey{
        items: [54, 65, 75, 74],
        operation: fn x -> Multimod.add(x, 6) end,
        divisor: 19,
        true_destination: 2,
        false_destination: 0
      },
      2 => %Monkey{
        items: [79, 60, 97],
        operation: fn x -> Multimod.square(x) end,
        divisor: 13,
        true_destination: 1,
        false_destination: 3
      },
      3 => %Monkey{
        items: [74],
        operation: fn x -> Multimod.add(x, 3) end,
        divisor: 17,
        true_destination: 0,
        false_destination: 1
      }
    }

  def play_catch(monkeys, worry_divisor, rounds),
    do:
      if(worry_divisor == 1,
        do:
          do_round(
            Enum.into(
              Enum.map(
                monkeys,
                fn {k, v} -> {k, %Monkey{v | items: Qex.new(Multimod.new_list(v.items))}} end
              ),
              %{}
            ),
            worry_divisor,
            rounds
          ),
        else:
          do_round(
            Enum.into(
              Enum.map(
                monkeys,
                fn {k, v} ->
                  {k, %Monkey{v | items: Qex.new(Multimod.new_list_with_val(v.items))}}
                end
              ),
              %{}
            ),
            worry_divisor,
            rounds
          )
      )

  def do_round(monkeys, _, 0), do: monkeys

  def do_round(monkeys, worry_divisor, rounds_remaining) do
    IO.puts(rounds_remaining)
    do_round(do_turn(monkeys, worry_divisor, 0), worry_divisor, rounds_remaining - 1)
  end

  def do_turn(monkeys, _, id) when id == map_size(monkeys), do: monkeys

  def do_turn(monkeys, worry_divisor, id) do
    monkey = Map.get(monkeys, id)
    true_monkey = Map.get(monkeys, monkey.true_destination)
    false_monkey = Map.get(monkeys, monkey.false_destination)
    item_count = Enum.count(monkey.items)

    {trues, falses} =
      Enum.reduce(monkey.items, {Qex.new(), Qex.new()}, fn item, {trues, falses} ->
        item = Multimod.divide(monkey.operation.(item), worry_divisor)

        if Multimod.divisible_by(item, monkey.divisor),
          do: {Qex.push(trues, item), falses},
          else: {trues, Qex.push(falses, item)}
      end)

    do_turn(
      %{
        monkeys
        | id => %Monkey{monkey | items: Qex.new(), inspected: monkey.inspected + item_count},
          monkey.true_destination => %Monkey{
            true_monkey
            | items: Qex.join(true_monkey.items, trues)
          },
          monkey.false_destination => %Monkey{
            false_monkey
            | items: Qex.join(false_monkey.items, falses)
          }
      },
      worry_divisor,
      id + 1
    )
  end
end
