defmodule Resources do
  defstruct [ore: 0, clay: 0, obsidian: 0, geode: 0]

  def spend(resources, cost) when resources.ore >= cost.ore
    and resources.clay >= cost.clay
    and resources.obsidian >= cost.obsidian
    and resources.geode >= cost.geode, do:
    {:ok, %Resources{
      ore: resources.ore - cost.ore,
      clay: resources.clay - cost.clay,
      obsidian: resources.obsidian - cost.obsidian,
      geode: resources.geode - cost.geode
    }}

  def spend(_, _), do: :error

  def add(%Resources{} = r1, r2), do: %Resources{
    ore: r1.ore + r2.ore,
    clay: r1.clay + r2.clay,
    obsidian: r1.obsidian + r2.obsidian,
    geode: r1.geode + r2.geode,
  }

  def subtract(%Resources{} = r1, r2), do: %Resources{
    ore: r1.ore - r2.ore,
    clay: r1.clay - r2.clay,
    obsidian: r1.obsidian - r2.obsidian,
    geode: r1.geode - r2.geode,
  }
end

defmodule Robots do
  defstruct [ore: 0, clay: 0, obsidian: 0, geode: 0]

  def harvest(robots, resources), do:
    %Resources{ore: resources.ore + robots.ore,
               clay: resources.clay + robots.clay,
               obsidian: resources.obsidian + robots.obsidian,
               geode: resources.geode + robots.geode}

  def try_build(robots, resources, cost, :ore) do
    turns = (((cost.ore - resources.ore) / robots.ore) |> Float.ceil() |> max(0) |> round()) + 1
    resources = 1..turns 
    |> Enum.reduce(resources, fn _, acc -> Resources.add(acc, robots) end)
    |> Resources.subtract(cost)

    {resources, %Robots{robots | ore: robots.ore + 1}, turns}
  end

  def try_build(robots, resources, cost, :clay) do
    turns = (((cost.ore - resources.ore) / robots.ore) |> Float.ceil() |> max(0) |> round()) + 1
    resources = 1..turns 
    |> Enum.reduce(resources, fn _, acc -> Resources.add(acc, robots) end)
    |> Resources.subtract(cost)

    {resources, %Robots{robots | clay: robots.clay + 1}, turns}
  end

  def try_build(%Robots{clay: 0}, _, _, :obsidian), do: nil
  def try_build(robots, resources, cost, :obsidian) do
    turns = max(
      (((cost.ore - resources.ore) / robots.ore) |> Float.ceil() |> max(0) |> round()) + 1,
      (((cost.clay - resources.clay) / robots.clay) |> Float.ceil() |> max(0) |> round()) + 1
    )
    resources = 1..turns 
    |> Enum.reduce(resources, fn _, acc -> Resources.add(acc, robots) end)
    |> Resources.subtract(cost)

    {resources, %Robots{robots | obsidian: robots.obsidian + 1}, turns}
  end

  def try_build(%Robots{obsidian: 0}, _, _, :geode), do: nil
  def try_build(robots, resources, cost, :geode) do
    turns = max(
      (((cost.ore - resources.ore) / robots.ore) |> Float.ceil() |> max(0) |> round()) + 1,
      (((cost.obsidian - resources.obsidian) / robots.obsidian) |> Float.ceil() |> max(0) |> round()) + 1
    )
    resources = 1..turns 
    |> Enum.reduce(resources, fn _, acc -> Resources.add(acc, robots) end)
    |> Resources.subtract(cost)

    {resources, %Robots{robots | geode: robots.geode + 1}, turns}
  end
end

defmodule RobotFactory do
  defstruct [:id, :ore_robot_cost, :clay_robot_cost, :obsidian_robot_cost, :geode_robot_cost]

  def new(description), do:
    description |> String.split(": ") |> parse()

  defp parse([<<"Blueprint ", id::binary>>, robot_specs]) do
    {ore_robot_cost, clay_robot_cost, obsidian_robot_cost, geode_robot_cost} =
      parse_robots(String.split(robot_specs, ". "))

    %RobotFactory{
      id: String.to_integer(id),
      ore_robot_cost: ore_robot_cost,
      clay_robot_cost: clay_robot_cost,
      obsidian_robot_cost: obsidian_robot_cost,
      geode_robot_cost: geode_robot_cost
    }
  end

  defp parse_robots([ore_robot, clay_robot, obsidian_robot, geode_robot]), do:
    {parse_robot(ore_robot), parse_robot(clay_robot), parse_robot(obsidian_robot), parse_robot(geode_robot)}

  defp parse_robot(<<"Each ore robot costs ", cost::bytes-size(1), " ore">>), do:
    %Resources{ore: String.to_integer(cost)}

  defp parse_robot(<<"Each clay robot costs ", cost::bytes-size(1), " ore">>), do:
    %Resources{ore: String.to_integer(cost)}

  defp parse_robot(<<"Each obsidian robot costs ", cost::binary>>) do
    %{"ore" => ore, "clay" => clay} = Regex.named_captures(
      ~r/(?<ore>\d+) ore and (?<clay>\d+) clay.*/, cost
    )

    %Resources{ore: String.to_integer(ore), clay: String.to_integer(clay)}
  end

  defp parse_robot(<<"Each geode robot costs ", cost::binary>>) do
    %{"ore" => ore, "obsidian" => obsidian} = Regex.named_captures(
      ~r/(?<ore>\d+) ore and (?<obsidian>\d+) obsidian.*/, cost
    )

    %Resources{ore: String.to_integer(ore), obsidian: String.to_integer(obsidian)}
  end

  def quality(factory) do
    IO.puts("====== " <> Integer.to_string(factory.id) <> " ======")
    BestResult.start_link(0)
    max_geodes(factory, %Resources{}, %Robots{ore: 1}, 24)
    geodes = BestResult.value()
    BestResult.stop()
    factory.id * geodes
  end

  def max_geodes(factory, turns) do
    IO.puts("====== " <> Integer.to_string(factory.id) <> " ======")
    BestResult.start_link(0)
    max_geodes(factory, %Resources{}, %Robots{ore: 1}, turns)
    geodes = BestResult.value()
    BestResult.stop()
    geodes
  end    

  defp max_geodes(_, %Resources{geode: geode}, _, 0) do
    BestResult.put_if_greater(geode)
    geode
  end

  defp max_geodes(factory, resources, robots, turns_remaining) do
    cond do
      too_many_robots?(factory, robots) -> 0
      max_potential(resources, robots, turns_remaining) < BestResult.value() -> 0
      true -> build_options(factory, resources, robots)
      |> Enum.reject(fn {_, _, turns_taken} -> turns_taken > turns_remaining end)
      |> Enum.map(fn {resources, robots, turns_taken} -> 
        max_geodes(factory, resources, robots, turns_remaining - turns_taken) 
      end)
      |> Enum.max(&>=/2, fn -> resources.geode + (robots.geode * turns_remaining) end)
      |> tap(&BestResult.put_if_greater(&1))
    end
  end

  defp build_options(factory, resources, robots) do
    [
      Robots.try_build(robots, resources, factory.geode_robot_cost, :geode),
      Robots.try_build(robots, resources, factory.obsidian_robot_cost, :obsidian),
      Robots.try_build(robots, resources, factory.clay_robot_cost, :clay),
      Robots.try_build(robots, resources, factory.ore_robot_cost, :ore)
    ]
    |> Enum.filter(&(&1))
  end

  defp max_potential(resources, robots, turns_remaining) do
    n = robots.geode + turns_remaining
    potential = ((n**2 + n) / 2) - ((robots.geode**2 + robots.geode) / 2)
    resources.geode + potential
  end

  defp too_many_robots?(factory, robots) do
    robots.ore > Enum.max([
      factory.ore_robot_cost.ore, 
      factory.clay_robot_cost.ore, 
      factory.obsidian_robot_cost.ore,
      factory.geode_robot_cost.ore]) or
    robots.clay > factory.obsidian_robot_cost.clay or
    robots.obsidian > factory.geode_robot_cost.obsidian
  end
end

defmodule Day19 do
  def part1(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&RobotFactory.new/1)
    |> Enum.map(&RobotFactory.quality/1)
    |> Enum.sum()

  def part2(file), do:
    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.take(3)
    |> Enum.map(&RobotFactory.new/1)
    |> Enum.map(&RobotFactory.max_geodes(&1, 32))
    |> Enum.product()
end