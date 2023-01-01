defmodule DoublyLinkedMapEntry do
  defstruct [:value, :next, :previous]
end

defmodule DoublyLinkedMap do
  defstruct [:start, :map]
  def new(list), do: do_new(%DoublyLinkedMap{start: 0, map: %{}}, list)

  def mix(%DoublyLinkedMap{} = dlmap), do: do_mix(dlmap, 0)

  defp do_new(%DoublyLinkedMap{map: map} = dlmap, [{value, index}]),
    do: %DoublyLinkedMap{
      dlmap
      | map:
          map |> Map.put(index, %DoublyLinkedMapEntry{value: value, next: 0, previous: index - 1})
    }

  defp do_new(%DoublyLinkedMap{map: map} = dlmap, [{value, index} | rest]),
    do:
      do_new(
        %DoublyLinkedMap{
          dlmap
          | map:
              map
              |> Map.put(index, %DoublyLinkedMapEntry{
                value: value,
                next: index + 1,
                previous: if(map_size(map) == 0, do: length(rest), else: index - 1)
              })
        },
        rest
      )

  defp do_mix(%DoublyLinkedMap{} = dlmap, index) when not is_map_key(dlmap.map, index), do: dlmap

  defp do_mix(%DoublyLinkedMap{map: map, start: start}, index) do
    current = map[index]

    length = map_size(map)
    move = rem(current.value, length - 1)

    efficient_move =
      cond do
        move > length / 2 -> move - (length - 1)
        move < -length / 2 -> move + (length - 1)
        true -> move
      end

    do_mix(
      %DoublyLinkedMap{
        map: map |> remove(index) |> insert(index, efficient_move),
        start: if(current.value == 0, do: index, else: start)
      },
      index + 1
    )
  end

  defp remove(map, key) do
    current = map[key]
    next_key = current.next
    previous_key = current.previous
    next = map[next_key]
    previous = map[previous_key]

    %{
      map
      | previous_key => %DoublyLinkedMapEntry{previous | next: next_key},
        next_key => %DoublyLinkedMapEntry{next | previous: previous_key}
    }
  end

  defp insert(map, key, 0) do
    current = map[key]
    next = map[current.next]
    previous = map[current.previous]

    %{
      map
      | current.previous => %DoublyLinkedMapEntry{previous | next: key},
        current.next => %DoublyLinkedMapEntry{next | previous: key}
    }
  end

  defp insert(map, key, moves) when moves > 0 do
    current = map[key]
    next = map[current.next]

    insert(
      %{map | key => %DoublyLinkedMapEntry{current | next: next.next, previous: current.next}},
      key,
      moves - 1
    )
  end

  defp insert(map, key, moves) when moves < 0 do
    current = map[key]
    previous = map[current.previous]

    insert(
      %{
        map
        | key => %DoublyLinkedMapEntry{
            current
            | next: current.previous,
              previous: previous.previous
          }
      },
      key,
      moves + 1
    )
  end

  def reindex(%DoublyLinkedMap{map: map, start: start} = dlmap),
    do: %DoublyLinkedMap{dlmap | map: do_reindex(map, %{}, start, 0)}

  def do_reindex(old_map, new_map, _, _) when map_size(old_map) == map_size(new_map), do: new_map

  def do_reindex(old_map, new_map, old_key, new_key),
    do:
      do_reindex(
        old_map,
        new_map
        |> Map.put(new_key, %DoublyLinkedMapEntry{
          old_map[old_key]
          | next: if(map_size(new_map) == map_size(old_map) - 1, do: 0, else: new_key + 1),
            previous: if(map_size(new_map) == 0, do: map_size(old_map) - 1, else: new_key - 1)
        }),
        old_map[old_key].next,
        new_key + 1
      )

  def take_indexed(%DoublyLinkedMap{map: map}, indices),
    do:
      indices
      |> Enum.map(&Integer.mod(&1, map_size(map)))
      |> Enum.map(&map[&1].value)
end

defmodule Day20 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.to_integer/1)
      |> Enum.with_index()
      |> DoublyLinkedMap.new()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.reindex()
      |> DoublyLinkedMap.take_indexed([1000, 2000, 3000])
      |> Enum.sum()

  def part2(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&String.to_integer/1)
      |> Enum.map(&(&1 * 811_589_153))
      |> Enum.with_index()
      |> DoublyLinkedMap.new()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.mix()
      |> DoublyLinkedMap.reindex()
      |> DoublyLinkedMap.take_indexed([1000, 2000, 3000])
      |> Enum.sum()
end
