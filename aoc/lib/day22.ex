defmodule ForceFieldBoard do
  defstruct row_ranges: %{}, column_ranges: %{}, walls: %MapSet{}, wrapping: :opposite

  def parse(board),
    do:
      board
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.reduce(%ForceFieldBoard{}, fn {line, y}, board ->
        line
        |> String.to_charlist()
        |> Enum.with_index(1)
        |> Enum.reduce(board, fn {char, x}, board ->
          case char do
            ?\s ->
              board

            ?. ->
              %ForceFieldBoard{
                board
                | row_ranges:
                    Map.put(board.row_ranges, y, Map.get(board.row_ranges, y, x..x).first..x),
                  column_ranges:
                    Map.put(
                      board.column_ranges,
                      x,
                      Map.get(board.column_ranges, x, y..y).first..y
                    )
              }

            ?# ->
              %ForceFieldBoard{
                board
                | row_ranges:
                    Map.put(board.row_ranges, y, Map.get(board.row_ranges, y, x..x).first..x),
                  column_ranges:
                    Map.put(
                      board.column_ranges,
                      x,
                      Map.get(board.column_ranges, x, y..y).first..y
                    ),
                  walls: MapSet.put(board.walls, {x, y})
              }
          end
        end)
      end)
end

defmodule ForceFieldBoardPosition do
  defstruct [:x, :y, facing: :right]

  def score(%ForceFieldBoardPosition{x: x, y: y, facing: facing}) do
    y * 1000 + x * 4 +
      case(facing) do
        :right -> 0
        :down -> 1
        :left -> 2
        :up -> 3
      end
  end

  def track(%ForceFieldBoardPosition{} = position, %ForceFieldBoard{} = board, directions),
    do: do_track(position, board, Integer.parse(directions))

  defp do_track(position, _, ""), do: position

  defp do_track(
         %ForceFieldBoardPosition{facing: :right} = position,
         board,
         <<"R", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :down}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :down} = position,
         board,
         <<"R", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :left}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :left} = position,
         board,
         <<"R", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :up}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :up} = position,
         board,
         <<"R", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :right}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :right} = position,
         board,
         <<"L", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :up}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :up} = position,
         board,
         <<"L", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :left}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :left} = position,
         board,
         <<"L", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :down}, board, directions)

  defp do_track(
         %ForceFieldBoardPosition{facing: :down} = position,
         board,
         <<"L", directions::binary>>
       ),
       do: do_track(%ForceFieldBoardPosition{position | facing: :right}, board, directions)

  defp do_track(position, board, {distance, directions}),
    do: do_track(move(position, board, distance), board, directions)

  defp do_track(position, board, directions),
    do: do_track(position, board, Integer.parse(directions))

  defp move(position, _, 0), do: position

  defp move(position, board, distance) do
    target = destination(position, board)

    if MapSet.member?(board.walls, {target.x, target.y}),
      do: position,
      else: move(target, board, distance - 1)
  end

  defp step(x, y, :right), do: {x + 1, y}
  defp step(x, y, :down), do: {x, y + 1}
  defp step(x, y, :left), do: {x - 1, y}
  defp step(x, y, :up), do: {x, y - 1}

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :down} = current,
         %ForceFieldBoard{wrapping: :opposite, column_ranges: column_ranges}
       ) do
    {_, ty} = step(x, y, :down)

    if ty in column_ranges[x],
      do: %ForceFieldBoardPosition{current | y: ty},
      else: %ForceFieldBoardPosition{current | y: column_ranges[x].first}
  end

  defp destination(%ForceFieldBoardPosition{x: x, y: y, facing: :up} = current, %ForceFieldBoard{
         wrapping: :opposite,
         column_ranges: column_ranges
       }) do
    {_, ty} = step(x, y, :up)

    if ty in column_ranges[x],
      do: %ForceFieldBoardPosition{current | y: ty},
      else: %ForceFieldBoardPosition{current | y: column_ranges[x].last}
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :right} = current,
         %ForceFieldBoard{wrapping: :opposite, row_ranges: row_ranges}
       ) do
    {tx, _} = step(x, y, :right)

    if tx in row_ranges[y],
      do: %ForceFieldBoardPosition{current | x: tx},
      else: %ForceFieldBoardPosition{current | x: row_ranges[y].first}
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :left} = current,
         %ForceFieldBoard{wrapping: :opposite, row_ranges: row_ranges}
       ) do
    {tx, _} = step(x, y, :left)

    if tx in row_ranges[y],
      do: %ForceFieldBoardPosition{current | x: tx},
      else: %ForceFieldBoardPosition{current | x: row_ranges[y].last}
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :down} = current,
         %ForceFieldBoard{wrapping: :cubic} = board
       ) do
    {_, ty} = step(x, y, :down)

    if ty in board.column_ranges[x],
      do: %ForceFieldBoardPosition{current | y: ty},
      else: map(board, %ForceFieldBoardPosition{current | y: ty})
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :up} = current,
         %ForceFieldBoard{wrapping: :cubic} = board
       ) do
    {_, ty} = step(x, y, :up)

    if ty in board.column_ranges[x],
      do: %ForceFieldBoardPosition{current | y: ty},
      else: map(board, %ForceFieldBoardPosition{current | y: ty})
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :right} = current,
         %ForceFieldBoard{wrapping: :cubic} = board
       ) do
    {tx, _} = step(x, y, :right)

    if tx in board.row_ranges[y],
      do: %ForceFieldBoardPosition{current | x: tx},
      else: map(board, %ForceFieldBoardPosition{current | x: tx})
  end

  defp destination(
         %ForceFieldBoardPosition{x: x, y: y, facing: :left} = current,
         %ForceFieldBoard{wrapping: :cubic} = board
       ) do
    {tx, _} = step(x, y, :left)

    if tx in board.row_ranges[y],
      do: %ForceFieldBoardPosition{current | x: tx},
      else: map(board, %ForceFieldBoardPosition{current | x: tx})
  end

  # x1  50 51 100 101 150
  #       +-----+-----+ y
  #       |  e' |  d' | 1
  #       |f'   |    b|
  #       |     |  a' | 50
  #       +-----+-----+
  #       |     |       51
  #       |g'  a|
  #       |     |       100
  # +-----+-----+
  # |  g  |     |       101
  # |f    |   b'|
  # |     |  c' |       150
  # +-----+-----+
  # |     |             151
  # |e   c|
  # |  d  |             200
  # +-----+ 

  # Edge a
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: 101,
        y: y,
        facing: :right
      })
      when y in 51..100,
      do: %ForceFieldBoardPosition{x: y + 50, y: 50, facing: :up}

  # Edge a'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: x, y: 51, facing: :down})
      when x in 101..150,
      do: %ForceFieldBoardPosition{x: 100, y: x - 50, facing: :left}

  # Edge b
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: 151,
        y: y,
        facing: :right
      })
      when y in 1..50,
      do: %ForceFieldBoardPosition{x: 100, y: 151 - y, facing: :left}

  # Edge b'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: 101,
        y: y,
        facing: :right
      })
      when y in 101..150,
      do: %ForceFieldBoardPosition{x: 150, y: 151 - y, facing: :left}

  # Edge c
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: 51,
        y: y,
        facing: :right
      })
      when y in 151..200,
      do: %ForceFieldBoardPosition{x: y - 100, y: 150, facing: :up}

  # Edge c'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: x,
        y: 151,
        facing: :down
      })
      when x in 51..100,
      do: %ForceFieldBoardPosition{x: 50, y: x + 100, facing: :left}

  # Edge d
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{
        x: x,
        y: 201,
        facing: :down
      })
      when x in 1..50,
      do: %ForceFieldBoardPosition{x: x + 100, y: 1, facing: :down}

  # Edge d'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: x, y: 0, facing: :up})
      when x in 101..150,
      do: %ForceFieldBoardPosition{x: x - 100, y: 200, facing: :up}

  # Edge e
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: 0, y: y, facing: :left})
      when y in 151..200,
      do: %ForceFieldBoardPosition{x: y - 100, y: 1, facing: :down}

  # Edge e'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: x, y: 0, facing: :up})
      when x in 51..100,
      do: %ForceFieldBoardPosition{x: 1, y: x + 100, facing: :right}

  # Edge f
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: 0, y: y, facing: :left})
      when y in 101..150,
      do: %ForceFieldBoardPosition{x: 51, y: 151 - y, facing: :right}

  # Edge f'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: 50, y: y, facing: :left})
      when y in 1..50,
      do: %ForceFieldBoardPosition{x: 1, y: 151 - y, facing: :right}

  # Edge g
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: x, y: 100, facing: :up})
      when x in 1..50,
      do: %ForceFieldBoardPosition{x: 51, y: x + 50, facing: :right}

  # Edge g'
  def map(%ForceFieldBoard{wrapping: :cubic}, %ForceFieldBoardPosition{x: 50, y: y, facing: :left})
      when y in 51..100,
      do: %ForceFieldBoardPosition{x: y - 50, y: 101, facing: :down}
end

defmodule Day22 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n\n")
      |> then(fn [board, directions] -> {ForceFieldBoard.parse(board), directions} end)
      |> then(fn {board, directions} ->
        ForceFieldBoardPosition.track(
          %ForceFieldBoardPosition{x: board.row_ranges[1].first, y: 1},
          board,
          directions
        )
      end)
      |> ForceFieldBoardPosition.score()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n\n")
      |> then(fn [board, directions] -> {ForceFieldBoard.parse(board), directions} end)
      |> then(fn {board, directions} ->
        ForceFieldBoardPosition.track(
          %ForceFieldBoardPosition{x: board.row_ranges[1].first, y: 1},
          %ForceFieldBoard{board | wrapping: :cubic},
          directions
        )
      end)
      |> ForceFieldBoardPosition.score()
end
