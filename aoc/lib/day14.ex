defmodule Day14 do
  def part1(file), do: file |> parse()

  def part2(file), do: file

  defp parse(file) do
    rows =
      file
      |> AOCUtil.lines()
      |> Enum.reject(&(&1 == ""))
      |> Enum.with_index()
      |> Enum.reduce(
        %{y_max: 0, x_max: 0, blocks_by_row: %{}, blocks_by_column: %{}, rollers: []},
        fn {row, y}, %{blocks_by_row: blocks_by_row} = acc ->
          acc =
            acc |> Map.put(:y_max, y) |> Map.put(:blocks_by_row, blocks_by_row |> Map.put(y, []))

          row
          |> String.to_charlist()
          |> Enum.with_index()
          |> Enum.reduce(acc, fn {c, x},
                                 %{
                                   x_max: x_max,
                                   blocks_by_row: blocks_by_row,
                                   blocks_by_column: blocks_by_column,
                                   rollers: []
                                 } = acc ->
            acc = acc |> Map.put(:x_max, max(x, x_max))

            case c do
              ?. ->
                acc

              ?# ->
                acc
                |> Map.put(
                  :blocks_by_row,
                  blocks_by_row |> Map.put(y, [x | Map.get(blocks_by_row, y)])
                )
                |> Map.put(
                  :blocks_by_column,
                  blocks_by_column |> Map.put(x, [y | Map.get(blocks_by_column, x, [])])
                )

              ?O ->
                acc |> Map.put(:rollers, [{x, y} | Map.get(acc, :rollers)])
            end
          end)
        end
      )

    %{
      y_max: length(rows),
      x_max: rows |> hd() |> then(fn {row, _} -> String.length(row) end),
      blocks_by_row: %{},
      blocks_by_column: %{},
      rollers: []
    }
  end
end
