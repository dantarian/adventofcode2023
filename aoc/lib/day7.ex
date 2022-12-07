defmodule Directory do
  defstruct size: 0, subdirectories: %{}, files: [], root: false
end

defmodule Day7 do
  def part1(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> sizes()
    |> Enum.sort()
    |> Enum.reduce_while(0, fn x, acc -> if x < 100000, do: {:cont, x + acc}, else: {:halt, acc} end)

  def part2(file) do
    file_sizes = file
    |> File.read!()
    |> String.split("\n")
    |> sizes()
    |> Enum.sort()

    space_used = List.last(file_sizes)
    space_remaining = 70_000_000 - space_used
    space_needed = 30_000_000 - space_remaining
    Enum.find(file_sizes, fn x -> x >= space_needed end)
  end

  defp sizes(commands), do: sizes([], %Directory{root: true}, tl(commands))

  # No more commands, we're done.
  defp sizes(acc, directory, []) do
    dir_size = Enum.sum(directory.files) + Enum.sum(Enum.map(Map.values(directory.subdirectories), fn x -> x.size end))
    if directory.root do
      [dir_size | acc]
    else
      dir_size = Enum.sum(directory.files) + Enum.sum(Enum.map(Map.values(directory.subdirectories), fn x -> x.size end))
      {[dir_size | acc], %Directory{directory | size: dir_size}, []}
    end
  end  

  # We can ignore ls commands.
  defp sizes(acc, directory, ["$ ls" | tail]), do: sizes(acc, directory, tail)

  # Descending and ascending the directory structure.
  defp sizes(acc, directory, ["$ cd .." | tail]) do
    dir_size = Enum.sum(directory.files) + Enum.sum(Enum.map(Map.values(directory.subdirectories), fn x -> x.size end))
    {[dir_size | acc], %Directory{directory | size: dir_size}, tail}
  end
  defp sizes(acc, directory, [<<?$, ?\s, ?c, ?d, ?\s, dir_name::binary>> | tail]) do
    {updated_acc, subdir, remaining_commands} = sizes(acc, directory.subdirectories[dir_name], tail)
    updated_subdirectories = Map.put(directory.subdirectories, dir_name, subdir)
    sizes(updated_acc, %Directory{directory | subdirectories: updated_subdirectories}, remaining_commands)
  end

  # Adding directories and files to the structure
  defp sizes(acc, directory, [<<?d, ?i, ?r, ?\s, dir_name::binary>> | tail]) do
    updated_subdirectories = Map.put(directory.subdirectories, dir_name, %Directory{})
    sizes(acc, %Directory{directory | subdirectories: updated_subdirectories}, tail)
  end
  defp sizes(acc, directory, [head | tail]) do
    updated_files = [ String.split(head) |> hd() |> String.to_integer() | directory.files ]
    sizes(acc, %Directory{directory | files: updated_files}, tail)
  end
end