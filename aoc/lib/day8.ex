defmodule Day8 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.with_index()
      |> scan()
      |> MapSet.size()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.with_index()
      |> scan_view()
      |> Enum.max()

  defp scan(lines), do: do_scan(MapSet.new(), [], %{}, lines)

  defp do_scan(visible, processed, _, []), do: reverse_scan(visible, processed)

  defp do_scan(visible, processed, max_columns, [{line, index} | tail]) do
    {visible, processed_line, max_columns} = scan_line(visible, max_columns, line, index)
    do_scan(visible, [{processed_line, index} | processed], max_columns, tail)
  end

  defp scan_line(visible, max_columns, line, row_index),
    do:
      do_scan_line(
        visible,
        [],
        max_columns,
        -1,
        String.to_charlist(line) |> Enum.with_index(),
        row_index
      )

  defp do_scan_line(visible, processed, max_columns, _, [], _),
    do: {visible, processed, max_columns}

  defp do_scan_line(visible, processed, max_columns, row_max, [{tree, index} | tail], row_index) do
    col_max = Map.get(max_columns, index, -1)

    visible =
      if tree > row_max or tree > col_max,
        do: MapSet.put(visible, {index, row_index}),
        else: visible

    max_columns = Map.put(max_columns, index, max(col_max, tree))
    row_max = max(row_max, tree)
    do_scan_line(visible, [{tree, index} | processed], max_columns, row_max, tail, row_index)
  end

  defp reverse_scan(visible, lines), do: do_reverse_scan(visible, %{}, lines)

  defp do_reverse_scan(visible, _, []), do: visible

  defp do_reverse_scan(visible, max_columns, [{line, index} | tail]) do
    {visible, _, max_columns} = do_scan_line(visible, [], max_columns, -1, line, index)
    do_reverse_scan(visible, max_columns, tail)
  end

  defp scan_view(lines), do: do_scan_view(%{}, [], %{}, lines)

  defp do_scan_view(scores, processed, _, []), do: reverse_view_scan(scores, processed)

  defp do_scan_view(scores, processed, cols, [{line, index} | tail]) do
    {scores, processed_line, cols} = scan_view_line(scores, cols, line, index)
    do_scan_view(scores, [{processed_line, index} | processed], cols, tail)
  end

  defp scan_view_line(scores, cols, line, row_index),
    do:
      do_scan_view_line(
        scores,
        [],
        cols,
        [],
        String.to_charlist(line) |> Enum.with_index(),
        row_index
      )

  defp do_scan_view_line(scores, processed, cols, _, [], _), do: {scores, processed, cols}

  defp do_scan_view_line(scores, processed, cols, row, [{tree, index} | tail], row_index) do
    {col_view, col_remaining} = Enum.split_while(Map.get(cols, index, []), fn x -> x < tree end)
    {row_view, row_remaining} = Enum.split_while(row, fn x -> x < tree end)
    col_score = length(col_view) + if Enum.empty?(col_remaining), do: 0, else: 1
    row_score = length(row_view) + if Enum.empty?(row_remaining), do: 0, else: 1

    scores =
      Map.put(
        scores,
        {row_index, index},
        Map.get(scores, {row_index, index}, 1) * col_score * row_score
      )

    do_scan_view_line(
      scores,
      [{tree, index} | processed],
      Map.put(cols, index, [tree | Map.get(cols, index, [])]),
      [tree | row],
      tail,
      row_index
    )
  end

  defp reverse_view_scan(scores, lines), do: do_reverse_view_scan(scores, %{}, lines)

  defp do_reverse_view_scan(scores, _, []), do: Map.values(scores)

  defp do_reverse_view_scan(scores, cols, [{line, index} | tail]) do
    {scores, _, cols} = do_scan_view_line(scores, [], cols, [], line, index)
    do_reverse_view_scan(scores, cols, tail)
  end
end
