defmodule SeedMapSegment do
  defstruct [:in_range, :out_range, :offset]
end

defmodule Day5 do
  def part1(file) do
    [seeds | maps] = file |> AOCUtil.blocks!()
    maps = maps |> Enum.map(fn block -> 
      block 
      |> String.split("\n")
      |> tl() 
      |> Enum.reject(fn line -> line == "" end)
      |> Enum.map(fn line -> 
        line 
        |> String.split() 
        |> Enum.map(&String.to_integer(&1))
        |> then(fn [dest_start, source_start, length | []] -> %SeedMapSegment{in_range: source_start..(source_start + length - 1), out_range: dest_start..(dest_start + length - 1), offset: dest_start - source_start} end)
      end)
    end)

    seeds 
    |> String.split(": ") 
    |> tl() 
    |> hd() 
    |> String.split() 
    |> Enum.map(&String.to_integer(&1))
    |> Enum.map(fn seed ->
      maps
      |> Enum.reduce(seed, fn map, input -> 
        (map |> Enum.reduce(0, fn %SeedMapSegment{in_range: range, offset: segment_offset}, offset -> if input in range, do: segment_offset, else: offset end)) + input
      end)
    end)
    |> Enum.min()
  end

  def part2(file) do
    [seeds | maps] = file |> AOCUtil.blocks!()
    maps = maps |> Enum.map(fn block -> 
      block 
      |> String.split("\n")
      |> tl() 
      |> Enum.reject(fn line -> line == "" end)
      |> Enum.map(fn line -> 
        line 
        |> String.split() 
        |> Enum.map(&String.to_integer(&1))
        |> then(fn [dest_start, source_start, length | []] -> %SeedMapSegment{in_range: source_start..(source_start + length - 1), out_range: dest_start..(dest_start + length - 1), offset: dest_start - source_start} end)
      end)
    end)

    seeds 
    |> String.split(": ") 
    |> tl() 
    |> hd() 
    |> String.split() 
    |> Enum.map(&String.to_integer(&1))
    |> ranges()
    |> apply_transforms(maps)
    |> Enum.map(fn start.._ -> start end)
    |> Enum.min()
  end

  defp apply_transforms(seed_ranges, maps), do: do_apply_transforms(seed_ranges, maps)

  defp do_apply_transforms(seed_ranges, []), do: seed_ranges
  defp do_apply_transforms(seed_ranges, [map | rest]), do: seed_ranges |> apply_map(map) |> do_apply_transforms(rest)

  defp apply_map(seed_ranges, transforms), do: do_apply_map(seed_ranges, transforms, [], [])

  defp do_apply_map(ranges, [], untransformed_ranges, transformed_ranges), do: ranges ++ untransformed_ranges ++ transformed_ranges
  defp do_apply_map([], [_ | other_transforms], untransformed_ranges, transformed_ranges), do: do_apply_map(untransformed_ranges, other_transforms, [], transformed_ranges)
  defp do_apply_map([range | other_ranges], [transform | _] = transforms, untransformed_ranges, transformed_ranges) do
    cond do
      Range.disjoint?(range, transform.in_range) -> do_apply_map(other_ranges, transforms, [range | untransformed_ranges], transformed_ranges)
      range.first >= transform.in_range.first && range.last <= transform.in_range.last -> 
        do_apply_map(other_ranges, transforms, untransformed_ranges, [(transform.out_range.first + (range.first - transform.in_range.first))..(transform.out_range.last - (transform.in_range.last - range.last)) | transformed_ranges])
      range.first < transform.in_range.first && range.last <= transform.in_range.last ->
        do_apply_map(other_ranges, transforms, [range.first..(transform.in_range.first - 1) | untransformed_ranges], [transform.out_range.first..(transform.out_range.last - (transform.in_range.last - range.last)) | transformed_ranges])
      range.first >= transform.in_range.first && range.last > transform.in_range.last ->
        do_apply_map(other_ranges, transforms, [(transform.in_range.last + 1)..range.last | untransformed_ranges], [transform.out_range.first + (range.first - transform.in_range.first)..transform.out_range.last | transformed_ranges])
      range.first < transform.in_range.first && range.last > transform.in_range.last ->
        do_apply_map(other_ranges, transforms, [range.first..(transform.in_range.first - 1), (transform.in_range.last + 1)..range.last | untransformed_ranges], [transform.out_range | transformed_ranges])
    end
  end
  
  defp ranges(list), do: do_ranges(list, [])

  defp do_ranges([], result), do: result
  defp do_ranges([start, length | rest], result), do: do_ranges(rest, [start..(start + length - 1) | result])
end
