defmodule Day13 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n\n")
      |> Enum.map(&process_pair/1)
      |> Enum.with_index(1)
      |> Enum.filter(fn {ordered, _} -> ordered end)
      |> Enum.map(fn {_, idx} -> idx end)
      |> Enum.sum()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.reject(fn x -> x == "" end)
      |> Enum.map(&Jason.decode!/1)
      |> then(fn list -> [[[2]] | [[[6]] | list]] end)
      |> Enum.sort(&ordered?/2)
      |> Enum.with_index(1)
      |> Enum.filter(fn {x, _} -> x == [[2]] or x == [[6]] end)
      |> Enum.map(fn {_, idx} -> idx end)
      |> Enum.product()

  defp process_pair(pair),
    do:
      pair
      |> String.split("\n")
      |> then(fn [left, right] -> {Jason.decode!(left), Jason.decode!(right)} end)
      |> then(&ordered?/1)

  defp ordered?({left, right}), do: ordered?(left, right)

  defp ordered?([lhead | _], [rhead | _])
       when is_integer(lhead) and is_integer(rhead) and lhead < rhead,
       do: true

  defp ordered?([lhead | _], [rhead | _])
       when is_integer(lhead) and is_integer(rhead) and lhead > rhead,
       do: false

  defp ordered?([lhead | ltail], [rhead | rtail]) when is_integer(lhead) and is_integer(rhead),
    do: ordered?(ltail, rtail)

  defp ordered?([lhead | ltail], [rhead | rtail]) when is_list(lhead) and is_list(rhead) do
    result = ordered?(lhead, rhead)
    if is_nil(result), do: ordered?(ltail, rtail), else: result
  end

  defp ordered?([lhead | ltail], [rhead | rtail]) when is_list(lhead) and is_integer(rhead),
    do: ordered?([lhead | ltail], [[rhead] | rtail])

  defp ordered?([lhead | ltail], [rhead | rtail]) when is_integer(lhead) and is_list(rhead),
    do: ordered?([[lhead] | ltail], [rhead | rtail])

  defp ordered?([], [_ | _]), do: true
  defp ordered?([_ | _], []), do: false
  defp ordered?([], []), do: nil
end
