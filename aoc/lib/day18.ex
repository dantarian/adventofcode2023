defmodule CavityTracker do
  defstruct known_external: %MapSet{}, known_internal: %MapSet{}
  use Agent

  def start_link(), do: Agent.start_link(fn -> %CavityTracker{} end, name: __MODULE__)

  def stop, do: Agent.stop(__MODULE__)

  def is_external?(point),
    do: Agent.get(__MODULE__, fn state -> MapSet.member?(state.known_external, point) end)

  def is_internal?(point),
    do: Agent.get(__MODULE__, fn state -> MapSet.member?(state.known_internal, point) end)

  def add_external(point),
    do:
      Agent.update(__MODULE__, fn state ->
        %CavityTracker{state | known_external: MapSet.put(state.known_external, point)}
      end)

  def add_internal(point),
    do:
      Agent.update(__MODULE__, fn state ->
        %CavityTracker{state | known_internal: MapSet.put(state.known_internal, point)}
      end)
end

defmodule Day18 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.split(&1, ","))
      |> Enum.map(fn [x, y, z] ->
        {String.to_integer(x), String.to_integer(y), String.to_integer(z)}
      end)
      |> MapSet.new()
      |> surface_area()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.split(&1, ","))
      |> Enum.map(fn [x, y, z] ->
        {String.to_integer(x), String.to_integer(y), String.to_integer(z)}
      end)
      |> MapSet.new()
      |> external_surface_area()

  defp surface_area(mapset, cavities \\ %MapSet{}),
    do:
      mapset
      |> Enum.map(&neighbours/1)
      |> Enum.map(fn points ->
        points
        |> Enum.reject(&(MapSet.member?(mapset, &1) or MapSet.member?(cavities, &1)))
        |> length()
      end)
      |> Enum.sum()

  defp external_surface_area(mapset) do
    CavityTracker.start_link()
    result = surface_area(mapset, find_cavities(mapset))
    CavityTracker.stop()
    result
  end

  defp find_cavities(lava) do
    {{minx, miny, minz}, {maxx, maxy, maxz}} =
      lava
      |> Enum.reduce(
        {{100, 100, 100}, {0, 0, 0}},
        fn {x, y, z}, {{minx, miny, minz}, {maxx, maxy, maxz}} ->
          {{min(minx, x), min(miny, y), min(minz, z)}, {max(maxx, x), max(maxy, y), max(maxz, z)}}
        end
      )

    for x <- minx..maxx, y <- miny..maxy, do: CavityTracker.add_external({x, y, minz})
    for x <- minx..maxx, y <- miny..maxy, do: CavityTracker.add_external({x, y, maxz})
    for y <- miny..maxy, z <- minz..maxz, do: CavityTracker.add_external({minx, y, z})
    for y <- miny..maxy, z <- minz..maxz, do: CavityTracker.add_external({maxx, y, z})
    for x <- minx..maxx, z <- minz..maxz, do: CavityTracker.add_external({x, miny, z})
    for x <- minx..maxx, z <- minz..maxz, do: CavityTracker.add_external({x, maxy, z})

    for x <- minx..maxx,
        y <- miny..maxy,
        z <- minz..maxz,
        !MapSet.member?(lava, {x, y, z}),
        is_internal?([{x, y, z}], lava, %MapSet{}),
        into: %MapSet{},
        do: {x, y, z}
  end

  defp is_internal?([], _, connected_points) do
    connected_points |> Enum.each(fn pt -> CavityTracker.add_internal(pt) end)
    true
  end

  defp is_internal?([point | remaining] = candidates, lava, connected_points) do
    cond do
      CavityTracker.is_internal?(point) ->
        is_internal?([], lava, connected_points |> MapSet.union(MapSet.new(candidates)))

      CavityTracker.is_external?(point) ->
        (candidates ++ MapSet.to_list(connected_points))
        |> Enum.each(fn pt -> CavityTracker.add_external(pt) end)

        false

      true ->
        candidates =
          neighbours(point)
          |> Enum.reject(fn pt -> MapSet.member?(lava, pt) end)
          |> Enum.reject(fn pt -> MapSet.member?(connected_points, pt) end)
          |> MapSet.new()
          |> MapSet.union(MapSet.new(remaining))
          |> MapSet.to_list()

        is_internal?(candidates, lava, connected_points |> MapSet.put(point))
    end
  end

  defp neighbours({x, y, z}),
    do: [
      {x - 1, y, z},
      {x, y - 1, z},
      {x, y, z - 1},
      {x + 1, y, z},
      {x, y + 1, z},
      {x, y, z + 1}
    ]
end
