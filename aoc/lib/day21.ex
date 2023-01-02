defmodule MonkeyOp do
  defstruct [:operation, :operand1, :operand2]

  def solve(%{} = map), do: process(map, map["root"])

  defp process(%{} = map, %MonkeyOp{operation: :equal, operand1: operand1, operand2: operand2}) do
    operand1 = process(map, map[operand1])
    operand2 = process(map, map[operand2])

    if is_integer(operand1),
      do: solve(operand2, operand1),
      else: solve(operand1, operand2)
  end

  defp process(%{}, %MonkeyOp{operation: :constant, operand1: operand1}), do: operand1

  defp process(%{}, %MonkeyOp{operation: :unknown}), do: []

  defp process(%{} = map, %MonkeyOp{operation: :add, operand1: operand1, operand2: operand2}) do
    operand1 = process(map, map[operand1])
    operand2 = process(map, map[operand2])

    cond do
      is_integer(operand1) and is_integer(operand2) -> operand1 + operand2
      is_integer(operand1) -> [fn x -> x - operand1 end | operand2]
      is_integer(operand2) -> [fn x -> x - operand2 end | operand1]
    end
  end

  defp process(%{} = map, %MonkeyOp{operation: :subtract, operand1: operand1, operand2: operand2}) do
    operand1 = process(map, map[operand1])
    operand2 = process(map, map[operand2])

    cond do
      is_integer(operand1) and is_integer(operand2) -> operand1 - operand2
      is_integer(operand1) -> [fn x -> operand1 - x end | operand2]
      is_integer(operand2) -> [fn x -> x + operand2 end | operand1]
    end
  end

  defp process(%{} = map, %MonkeyOp{operation: :multiply, operand1: operand1, operand2: operand2}) do
    operand1 = process(map, map[operand1])
    operand2 = process(map, map[operand2])

    cond do
      is_integer(operand1) and is_integer(operand2) -> operand1 * operand2
      is_integer(operand1) -> [fn x -> div(x, operand1) end | operand2]
      is_integer(operand2) -> [fn x -> div(x, operand2) end | operand1]
    end
  end

  defp process(%{} = map, %MonkeyOp{operation: :divide, operand1: operand1, operand2: operand2}) do
    operand1 = process(map, map[operand1])
    operand2 = process(map, map[operand2])

    cond do
      is_integer(operand1) and is_integer(operand2) -> div(operand1, operand2)
      is_integer(operand1) -> [fn x -> div(operand1, x) end | operand2]
      is_integer(operand2) -> [fn x -> x * operand2 end | operand1]
    end
  end

  defp solve([], value), do: value
  defp solve([func | rest], value), do: solve(rest, func.(value))
end

defmodule Day21 do
  def part1(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse/1)
    |> Enum.into(%{})
    |> then(fn m -> m["root"].(m) end)

  def part2(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse_advanced/1)
    |> Enum.into(%{})
    |> then(fn m -> MonkeyOp.solve(m) end)

  defp parse(line), do:
    line
    |> String.split(": ")
    |> then(fn [label, definition] -> {label, parse_definition(definition)} end)

  defp parse_definition(<<operand1::bytes-size(4), " + ", operand2::bytes-size(4)>>), do:
    fn m -> m[operand1].(m) + m[operand2].(m) end

  defp parse_definition(<<operand1::bytes-size(4), " - ", operand2::bytes-size(4)>>), do:
    fn m -> m[operand1].(m) - m[operand2].(m) end

  defp parse_definition(<<operand1::bytes-size(4), " * ", operand2::bytes-size(4)>>), do:
    fn m -> m[operand1].(m) * m[operand2].(m) end

  defp parse_definition(<<operand1::bytes-size(4), " / ", operand2::bytes-size(4)>>), do:
    fn m -> div(m[operand1].(m), m[operand2].(m)) end

  defp parse_definition(str), do: fn _ -> String.to_integer(str) end

  defp parse_advanced(line), do:
    line
    |> String.split(": ")
    |> then(fn [label, definition] -> {label, parse_def_adv(label, definition)} end)
  
  defp parse_def_adv("root", <<operand1::bytes-size(4), _::bytes-size(3), operand2::bytes-size(4)>>), do:
    %MonkeyOp{operation: :equal, operand1: operand1, operand2: operand2}

  defp parse_def_adv("humn", _), do:
    %MonkeyOp{operation: :unknown, operand1: []}

  defp parse_def_adv(_, <<operand1::bytes-size(4), " + ", operand2::bytes-size(4)>>), do:
    %MonkeyOp{operation: :add, operand1: operand1, operand2: operand2}

  defp parse_def_adv(_, <<operand1::bytes-size(4), " - ", operand2::bytes-size(4)>>), do:
    %MonkeyOp{operation: :subtract, operand1: operand1, operand2: operand2}

  defp parse_def_adv(_, <<operand1::bytes-size(4), " * ", operand2::bytes-size(4)>>), do:
    %MonkeyOp{operation: :multiply, operand1: operand1, operand2: operand2}

  defp parse_def_adv(_, <<operand1::bytes-size(4), " / ", operand2::bytes-size(4)>>), do:
    %MonkeyOp{operation: :divide, operand1: operand1, operand2: operand2}

  defp parse_def_adv(_, str), do: %MonkeyOp{operation: :constant, operand1: String.to_integer(str)}
end