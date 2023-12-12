defmodule Day12 do
  def part1(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(&parse(&1))
    |> Enum.reduce({%{}, 0}, fn {template, spec}, {cache, total} ->
      {cache, subtotal} = possible_arrangements(template, spec, cache)
      {cache, total + subtotal}
    end)
    |> then(fn {_, total} -> total end)
  end

  def part2(file) do
    file
    |> AOCUtil.lines!()
    |> Enum.map(&parse(&1, 5))
    |> Enum.reduce({%{}, 0}, fn {template, spec}, {cache, total} ->
      {cache, subtotal} = possible_arrangements(template, spec, cache)
      {cache, total + subtotal}
    end)
    |> then(fn {_, total} -> total end)
  end

  defp parse(line, duplication \\ 1) do
    [template, spec | []] = line |> String.split()

    template =
      template
      |> List.duplicate(duplication)
      |> Enum.join("?")
      |> String.trim(".")
      |> String.replace(~r/\.+/, ".")

    spec =
      spec
      |> List.duplicate(duplication)
      |> Enum.join(",")
      |> String.split(",")
      |> Enum.map(&String.to_integer(&1))

    {template, spec}
  end

  defp possible_arrangements(template, [], cache) do
    if(String.contains?(template, "#"), do: {cache, 0}, else: {cache, 1})
  end

  defp possible_arrangements("", _, cache) do
    {cache, 0}
  end

  defp possible_arrangements(template, [first | rest] = spec, cache) do
    template = template |> String.trim(".")

    cond do
      String.length(template) < Enum.sum(spec) + length(spec) - 1 ->
        {cache, 0}

      Map.has_key?(cache, {template, spec}) ->
        {cache, Map.get(cache, {template, spec})}

      Regex.compile!("^[#?]{#{first}}$") |> Regex.match?(template) ->
        {cache, 1}

      Regex.compile!("^[#?]{#{first}}[.?]") |> Regex.match?(template) ->
        {cache, subtotal} =
          possible_arrangements(template |> String.slice((first + 1)..-1), rest, cache)

        {cache, alternatives} =
          if template |> String.starts_with?("#"),
            do: {cache, 0},
            else: possible_arrangements(template |> String.slice(1..-1), spec, cache)

        {cache |> Map.put({template, spec}, subtotal + alternatives), subtotal + alternatives}

      true ->
        {cache, alternatives} =
          if template |> String.starts_with?("#"),
            do: {cache, 0},
            else: possible_arrangements(template |> String.slice(1..-1), spec, cache)

        {cache |> Map.put({template, spec}, alternatives), alternatives}
    end
  end
end
