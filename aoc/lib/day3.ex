defmodule EngineAddress do
  @enforce_keys [:x, :y]
  defstruct [:x, :y]

  def neighbours(%EngineAddress{x: x, y: y}),
    do: [
      %EngineAddress{x: x - 1, y: y - 1},
      %EngineAddress{x: x, y: y - 1},
      %EngineAddress{x: x + 1, y: y - 1},
      %EngineAddress{x: x - 1, y: y},
      %EngineAddress{x: x + 1, y: y},
      %EngineAddress{x: x - 1, y: y + 1},
      %EngineAddress{x: x, y: y + 1},
      %EngineAddress{x: x + 1, y: y + 1}
    ]
end

defmodule EngineSchematic do
  defstruct symbols: %{}, parts: %{}, addresses: %{}

  def parse(file),
    do:
      file
      |> AOCUtil.lines!()
      |> Enum.with_index()
      |> Enum.reduce(%EngineSchematic{}, &EngineSchematic.parse_line(&1, &2))

  def parse_line({line, y}, schematic) do
    do_parse_line(line |> String.to_charlist() |> Enum.with_index(), y, {:null, :null}, schematic)
  end

  def sum_connected_parts(%EngineSchematic{symbols: symbols, parts: parts, addresses: addresses}) do
    symbols
    |> Enum.flat_map(fn {addr, _} -> EngineAddress.neighbours(addr) end)
    |> Enum.map(fn addr -> Map.get(addresses, addr) end)
    |> Enum.uniq()
    |> Enum.map(fn addr -> Map.get(parts, addr, 0) end)
    |> Enum.sum()
  end

  defp connected_parts(
         %EngineSchematic{addresses: addresses, parts: parts},
         %EngineAddress{} = addr
       ) do
    addr
    |> EngineAddress.neighbours()
    |> Enum.map(fn addr -> Map.get(addresses, addr) end)
    |> Enum.filter(fn x -> x end)
    |> Enum.uniq()
    |> Enum.map(fn addr -> Map.get(parts, addr) end)
  end

  def sum_gears(%EngineSchematic{symbols: symbols} = schematic) do
    symbols
    |> Enum.filter(fn {_, c} -> c == ?* end)
    |> Enum.map(fn {addr, _} -> connected_parts(schematic, addr) end)
    |> Enum.filter(fn list -> length(list) == 2 end)
    |> Enum.map(&Enum.product(&1))
    |> Enum.sum()
  end

  defp do_parse_line([], _, {:null, :null}, schematic), do: schematic

  defp do_parse_line(
         [],
         _,
         {%EngineAddress{} = addr, n},
         %EngineSchematic{parts: parts} = schematic
       ),
       do: %{schematic | parts: Map.put(parts, addr, n)}

  defp do_parse_line(
         [{c, x} | rest],
         y,
         {:null, :null},
         %EngineSchematic{addresses: addresses} = schematic
       )
       when c >= ?0 and c <= ?9 do
    addr = %EngineAddress{x: x, y: y}

    do_parse_line(rest, y, {addr, c - ?0}, %{
      schematic
      | addresses: Map.put(addresses, addr, addr)
    })
  end

  defp do_parse_line(
         [{c, x} | rest],
         y,
         {%EngineAddress{} = addr, n},
         %EngineSchematic{addresses: addresses} = schematic
       )
       when c >= ?0 and c <= ?9 do
    do_parse_line(rest, y, {addr, n * 10 + c - ?0}, %{
      schematic
      | addresses: Map.put(addresses, %EngineAddress{x: x, y: y}, addr)
    })
  end

  defp do_parse_line(
         [{?., _} | rest],
         y,
         {:null, :null},
         schematic
       ) do
    do_parse_line(rest, y, {:null, :null}, schematic)
  end

  defp do_parse_line(
         [{?., _} | rest],
         y,
         {%EngineAddress{} = addr, n},
         %EngineSchematic{parts: parts} = schematic
       ) do
    do_parse_line(rest, y, {:null, :null}, %{schematic | parts: Map.put(parts, addr, n)})
  end

  defp do_parse_line(
         [{c, x} | rest],
         y,
         {:null, :null},
         %EngineSchematic{symbols: symbols} = schematic
       ) do
    do_parse_line(rest, y, {:null, :null}, %{
      schematic
      | symbols: Map.put(symbols, %EngineAddress{x: x, y: y}, c)
    })
  end

  defp do_parse_line(
         [{c, x} | rest],
         y,
         {%EngineAddress{} = addr, n},
         %EngineSchematic{symbols: symbols, parts: parts} = schematic
       ) do
    do_parse_line(rest, y, {:null, :null}, %{
      schematic
      | symbols: Map.put(symbols, %EngineAddress{x: x, y: y}, c),
        parts: Map.put(parts, addr, n)
    })
  end
end

defmodule Day3 do
  def part1(file),
    do:
      file
      |> EngineSchematic.parse()
      |> EngineSchematic.sum_connected_parts()

  def part2(file), do: file |> EngineSchematic.parse() |> EngineSchematic.sum_gears()
end
