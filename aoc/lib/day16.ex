defmodule Valve do
  defstruct [:flow_rate, :tunnels, open?: false, done?: false]

  def new(flow_rate, tunnels),
    do: %Valve{
      flow_rate: flow_rate,
      tunnels: tunnels,
      open?: flow_rate == 0,
      done?: flow_rate == 0 and length(tunnels) == 1
    }

  def open(valve), do: %Valve{valve | open?: true}

  def done(valve), do: %Valve{valve | done?: true}

  def check_done(valve, valves),
    do:
      if(valve.open? and valve.tunnels |> Enum.reject(&valves[&1].done?) |> length() <= 1,
        do: done(valve),
        else: valve
      )

  def value(valve, turns_remaining), do: valve.flow_rate * turns_remaining

  def potential(valves, turns_remaining),
    do:
      (valves
       |> Map.values()
       |> Enum.reject(& &1.open?)
       |> Enum.map(& &1.flow_rate)
       |> Enum.sum()) * (turns_remaining - 1)
end

defmodule ValveAgent do
  defstruct location: "AA", previous: nil, best_node_scores: %{}
end

defmodule BestResult do
  use Agent

  def start_link(initial_value), do: Agent.start_link(fn -> initial_value end, name: __MODULE__)

  def value, do: Agent.get(__MODULE__, fn state -> state end)

  def put_if_greater(candidate),
    do:
      Agent.update(__MODULE__, fn state ->
        if candidate > state, do: IO.inspect(candidate), else: state
      end)
end

defmodule TwoAgentState do
  defstruct [:agent1, :agent2, :valves, :turns_remaining, value: 0]

  def max_flow(%TwoAgentState{} = state) do
    cond do
      state.turns_remaining == 0 ->
        BestResult.put_if_greater(state.value)

      state.valves |> Map.values() |> Enum.all?(& &1.open?) ->
        BestResult.put_if_greater(state.value)

      state.value + Valve.potential(state.valves, state.turns_remaining) < BestResult.value() ->
        0

      true ->
        options(state) |> Enum.map(& &1.()) |> Enum.max(&>=/2, fn -> state.value end)
    end
  end

  defp options(%TwoAgentState{agent1: agent1, agent2: agent2} = state) do
    agent1_options =
      state.valves[agent1.location].tunnels
      |> Enum.reject(&state.valves[&1].done?)
      |> Enum.reject(fn x -> x == agent1.previous end)
      |> Enum.reject(fn x -> Map.get(agent1.best_node_scores, x) == state.value end)
      |> Enum.map(&{:move, &1})

    agent2_options =
      state.valves[agent2.location].tunnels
      |> Enum.reject(&state.valves[&1].done?)
      |> Enum.reject(fn x -> x == agent2.previous end)
      |> Enum.reject(fn x -> Map.get(agent2.best_node_scores, x) == state.value end)
      |> Enum.map(&{:move, &1})

    agent1_options =
      if state.valves[agent1.location].open?,
        do: agent1_options,
        else: [{:open, agent1.location} | agent1_options]

    agent2_options =
      if agent1.location == agent2.location or state.valves[agent2.location].open?,
        do: agent2_options,
        else: [{:open, agent2.location} | agent2_options]

    for {agent1_action, agent1_location} <- agent1_options,
        {agent2_action, agent2_location} <- agent2_options,
        do: next_state(state, agent1_action, agent1_location, agent2_action, agent2_location)
  end

  defp next_state(state, agent1_action, agent1_location, agent2_action, agent2_location)
       when agent1_action == :open and agent2_action == :open,
       do: fn ->
         new_turns_remaining = state.turns_remaining - 1

         new_value =
           state.value +
             Valve.value(state.valves[agent1_location], new_turns_remaining) +
             Valve.value(state.valves[agent2_location], new_turns_remaining)

         max_flow(%TwoAgentState{
           agent1: %ValveAgent{
             state.agent1
             | previous: agent1_location,
               best_node_scores:
                 Map.put(state.agent1.best_node_scores, agent1_location, new_value)
           },
           agent2: %ValveAgent{
             state.agent2
             | previous: agent2_location,
               best_node_scores:
                 Map.put(state.agent2.best_node_scores, agent2_location, new_value)
           },
           valves:
             state.valves
             |> Map.put(
               agent1_location,
               state.valves[agent1_location] |> Valve.open() |> Valve.check_done(state.valves)
             )
             |> Map.put(
               agent2_location,
               state.valves[agent2_location] |> Valve.open() |> Valve.check_done(state.valves)
             ),
           turns_remaining: new_turns_remaining,
           value: new_value
         })
       end

  defp next_state(state, agent1_action, agent1_location, _, agent2_location)
       when agent1_action == :open,
       do: fn ->
         new_turns_remaining = state.turns_remaining - 1

         new_value =
           state.value +
             Valve.value(state.valves[agent1_location], new_turns_remaining)

         new_valves =
           state.valves
           |> Map.put(
             agent1_location,
             state.valves[agent1_location] |> Valve.open() |> Valve.check_done(state.valves)
           )

         new_valves =
           if agent1_location == agent2_location,
             do: new_valves,
             else:
               new_valves
               |> Map.put(
                 agent2_location,
                 new_valves[agent2_location] |> Valve.check_done(new_valves)
               )

         max_flow(%TwoAgentState{
           agent1: %ValveAgent{
             state.agent1
             | previous: agent1_location,
               best_node_scores:
                 Map.put(state.agent1.best_node_scores, agent1_location, new_value)
           },
           agent2: %ValveAgent{
             location: agent2_location,
             previous: state.agent2.location,
             best_node_scores: Map.put(state.agent2.best_node_scores, agent2_location, new_value)
           },
           valves: new_valves,
           turns_remaining: new_turns_remaining,
           value: new_value
         })
       end

  defp next_state(state, _, agent1_location, agent2_action, agent2_location)
       when agent2_action == :open,
       do: fn ->
         new_turns_remaining = state.turns_remaining - 1

         new_value =
           state.value +
             Valve.value(state.valves[agent2_location], new_turns_remaining)

         new_valves =
           state.valves
           |> Map.put(
             agent2_location,
             state.valves[agent2_location] |> Valve.open() |> Valve.check_done(state.valves)
           )

         new_valves =
           if agent1_location == agent2_location,
             do: new_valves,
             else:
               new_valves
               |> Map.put(
                 agent1_location,
                 new_valves[agent1_location] |> Valve.check_done(new_valves)
               )

         max_flow(%TwoAgentState{
           agent1: %ValveAgent{
             location: agent1_location,
             previous: state.agent1.location,
             best_node_scores: Map.put(state.agent1.best_node_scores, agent1_location, new_value)
           },
           agent2: %ValveAgent{
             state.agent2
             | previous: agent2_location,
               best_node_scores:
                 Map.put(state.agent2.best_node_scores, agent2_location, new_value)
           },
           valves: new_valves,
           turns_remaining: new_turns_remaining,
           value: new_value
         })
       end

  defp next_state(state, _, agent1_location, _, agent2_location),
    do: fn ->
      new_turns_remaining = state.turns_remaining - 1

      max_flow(%TwoAgentState{
        agent1: %ValveAgent{
          state.agent1
          | location: agent1_location,
            previous: state.agent1.location
        },
        agent2: %ValveAgent{
          state.agent2
          | location: agent2_location,
            previous: state.agent2.location
        },
        valves:
          state.valves
          |> Map.put(
            agent1_location,
            state.valves[agent1_location] |> Valve.check_done(state.valves)
          )
          |> Map.put(
            agent2_location,
            state.valves[agent2_location] |> Valve.check_done(state.valves)
          ),
        turns_remaining: new_turns_remaining,
        value: state.value
      })
    end
end

defmodule Day16 do
  def part1(file),
    do:
      file
      |> File.read!()
      |> String.split("\n")
      |> Enum.map(&parse_line/1)
      |> Enum.into(%{})
      |> max_flow("AA", 30, [], %{})
      |> hd()
      |> elem(1)

  def part2(file, min_threshold) do
    BestResult.start_link(min_threshold)

    file
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(&parse_line/1)
    |> Enum.into(%{})
    |> then(fn valves ->
      TwoAgentState.max_flow(%TwoAgentState{
        agent1: %ValveAgent{},
        agent2: %ValveAgent{},
        valves: valves,
        turns_remaining: 26,
        value: 0
      })
    end)

    BestResult.value()
  end

  defp parse_line("Valve " <> <<name::binary-size(2)>> <> " has flow rate=" <> rest),
    do: {
      name,
      rest
      |> Integer.parse()
      |> then(fn {flow_rate, rest} -> Valve.new(flow_rate, parse_tunnels(rest)) end)
    }

  defp parse_tunnels("; tunnel leads to valve " <> tunnel), do: [tunnel]
  defp parse_tunnels("; tunnels lead to valves " <> tunnels), do: tunnels |> String.split(", ")

  defp max_flow(valves, current, turns_remaining, path, best_node_scores)
  defp max_flow(_, _, 0, path, _), do: path

  defp max_flow(valves, current, turns_remaining, path, best_node_scores) do
    current_value = if path == [], do: 0, else: path |> hd() |> elem(1)

    move_options =
      valves[current].tunnels
      |> Enum.reject(&valves[&1].done?)
      |> Enum.reject(fn x -> path != [] and x == path |> hd() |> elem(0) end)
      |> Enum.reject(fn x -> Map.get(best_node_scores, x) == current_value end)
      |> Enum.map(&move(&1, valves, current, turns_remaining, path, best_node_scores))

    options =
      if valves[current].open?,
        do: move_options,
        else: [open(valves, current, turns_remaining, path, best_node_scores) | move_options]

    options
    |> Enum.map(& &1.())
    |> Enum.max_by(fn [{_, v} | _] -> v end, &>=/2, fn -> path end)
  end

  defp open(valves, current, turns_remaining, path, best_node_scores) when length(path) == 0,
    do: fn ->
      max_flow(
        Map.put(valves, current, valves[current] |> Valve.open() |> Valve.check_done(valves)),
        current,
        turns_remaining - 1,
        [{current, Valve.value(valves[current], turns_remaining - 1)}],
        Map.put(best_node_scores, current, Valve.value(valves[current], turns_remaining - 1))
      )
    end

  defp open(valves, current, turns_remaining, [{_, value} | _] = path, best_node_scores),
    do: fn ->
      max_flow(
        Map.put(valves, current, valves[current] |> Valve.open() |> Valve.check_done(valves)),
        current,
        turns_remaining - 1,
        [{current, value + Valve.value(valves[current], turns_remaining - 1)} | path],
        Map.put(
          best_node_scores,
          current,
          value + Valve.value(valves[current], turns_remaining - 1)
        )
      )
    end

  defp move(target, valves, current, turns_remaining, path, best_node_scores)
       when length(path) == 0,
       do: fn ->
         max_flow(
           valves,
           target,
           turns_remaining - 1,
           [{current, 0}],
           Map.put(best_node_scores, current, 0)
         )
       end

  defp move(target, valves, current, turns_remaining, [{_, value} | _] = path, best_node_scores),
    do: fn ->
      max_flow(
        valves,
        target,
        turns_remaining - 1,
        [{current, value} | path],
        Map.put(best_node_scores, current, value)
      )
    end
end
