defmodule Day19 do
  @full_range 1..4000

  defmodule Part do
    defstruct [:x, :m, :a, :s]

    @spec value(%Day19.Part{
            :a => number(),
            :m => number(),
            :s => number(),
            :x => number()
          }) :: number()
    def value(%Part{x: x, m: m, a: a, s: s}), do: x + m + a + s
  end

  defmodule SuperPart do
    defstruct [:x, :m, :a, :s]

    def split(%SuperPart{} = part, attribute, position) when attribute in [:x, :m, :a, :s] do
      range = Map.get(part, attribute)

      cond do
        position <= range.first ->
          {nil, part}

        position > range.last ->
          {part, nil}

        true ->
          {%{part | attribute => range.first..(position - 1)},
           %{part | attribute => position..range.last}}
      end
    end

    @spec size(%Day19.SuperPart{
            :a => Range.t(),
            :m => Range.t(),
            :s => Range.t(),
            :x => Range.t()
          }) :: number()
    def size(%SuperPart{x: x, m: m, a: a, s: s}),
      do: [x, m, a, s] |> Enum.map(&Range.size/1) |> Enum.product()
  end

  def always(_), do: true

  defmodule WorkflowStep do
    @enforce_keys [:outcome]
    defstruct [
      :outcome,
      attribute: nil,
      comparator: nil,
      comparand: nil,
      condition: &Day19.always/1
    ]

    def apply(%WorkflowStep{} = step, %Part{} = part) do
      if step.condition.(part), do: step.outcome, else: :skip
    end

    def apply(%WorkflowStep{} = step, %SuperPart{} = part) do
      %{attribute: attribute, comparator: comparator, comparand: comparand, outcome: outcome} =
        step

      cond do
        comparator == (&>/2) ->
          case SuperPart.split(part, attribute, comparand + 1) do
            {nil, part} -> [{part, outcome}]
            {part, nil} -> [{part, :next}]
            {part1, part2} -> [{part1, :next}, {part2, outcome}]
          end

        comparator == (&</2) ->
          case SuperPart.split(part, attribute, comparand) do
            {nil, part} -> [{part, :next}]
            {part, nil} -> [{part, outcome}]
            {part1, part2} -> [{part1, outcome}, {part2, :next}]
          end

        comparator == nil ->
          [{part, outcome}]
      end
    end
  end

  defmodule Workflow do
    @enforce_keys [:steps]
    defstruct [:steps]

    def apply(%Workflow{steps: steps}, %Part{} = part), do: do_apply(steps, part)

    def apply(%Workflow{steps: steps}, %SuperPart{} = part),
      do: do_apply_super(steps, [{part, :next}])

    defp do_apply([step | steps], part) do
      case WorkflowStep.apply(step, part) do
        :skip -> do_apply(steps, part)
        other -> other
      end
    end

    defp do_apply_super([], parts), do: parts

    defp do_apply_super([step | steps], parts) do
      do_apply_super(
        steps,
        parts
        |> Enum.flat_map(fn {part, outcome} ->
          if outcome == :next, do: WorkflowStep.apply(step, part), else: [{part, outcome}]
        end)
      )
    end
  end

  def part1(file), do: file |> parse() |> sum_acceptable()

  def part2(file), do: file |> parse() |> then(&elem(&1, 0)) |> count_acceptable()

  defp parse(file) do
    [workflows, parts] = file |> AOCUtil.blocks!()

    {workflows |> parse_workflows(), parts |> parse_parts()}
  end

  defp parse_workflows(workflows) do
    workflows |> String.split("\n") |> Enum.map(&parse_workflow/1) |> Map.new()
  end

  defp parse_workflow(workflow) do
    [name, steps] = Regex.run(~r/^(.*)\{(.*)\}$/, workflow, capture: :all_but_first)
    {name, parse_steps(steps)}
  end

  defp parse_steps(steps) do
    %Workflow{steps: steps |> String.split(",") |> Enum.map(&parse_step/1)}
  end

  defp parse_step("A"), do: %WorkflowStep{outcome: :accept}
  defp parse_step("R"), do: %WorkflowStep{outcome: :reject}

  defp parse_step(step) do
    case step |> String.split(":") do
      [destination] ->
        %WorkflowStep{outcome: {:redirect, destination}}

      [<<attr::binary-size(1), cmp::binary-size(1), val::binary>>, outcome] ->
        outcome =
          case outcome do
            "A" -> :accept
            "R" -> :reject
            destination -> {:redirect, destination}
          end

        val = String.to_integer(val)

        attr =
          case attr do
            "x" -> :x
            "m" -> :m
            "a" -> :a
            "s" -> :s
          end

        cmp =
          case cmp do
            ">" -> &>/2
            "<" -> &</2
          end

        %WorkflowStep{
          condition: fn %Part{} = part -> cmp.(part[attr], val) end,
          outcome: outcome,
          attribute: attr,
          comparator: cmp,
          comparand: val
        }
    end
  end

  defp parse_parts(parts) do
    parts |> String.split("\n") |> Enum.map(&parse_part/1)
  end

  defp parse_part(part) do
    [x, m, a, s] =
      Regex.run(~r/^\{x=(\d+),m=(\d+),a=(\d+),s=(\d+)\}$/, part, capture: :all_but_first)

    %Part{
      x: x |> String.to_integer(),
      m: m |> String.to_integer(),
      a: a |> String.to_integer(),
      s: s |> String.to_integer()
    }
  end

  defp sum_acceptable({workflows, parts}) do
    parts
    |> Enum.filter(fn part -> process(part, workflows) == :accept end)
    |> Enum.map(&Part.value/1)
    |> Enum.sum()
  end

  defp process(part, workflows), do: do_process(part, "in", workflows)

  defp do_process(part, workflow_name, workflows) do
    case Workflow.apply(workflows |> Map.get(workflow_name), part) do
      {:redirect, name} -> do_process(part, name, workflows)
      other -> other
    end
  end

  defp count_acceptable(workflows) do
    do_count_acceptable(
      [
        {%SuperPart{x: @full_range, m: @full_range, a: @full_range, s: @full_range},
         {:redirect, "in"}}
      ],
      workflows,
      0
    )
  end

  defp do_count_acceptable([], _, total), do: total

  defp do_count_acceptable([part | parts], workflows, total) do
    {part, outcome} = part

    case outcome do
      :accept ->
        do_count_acceptable(parts, workflows, total + SuperPart.size(part))

      :reject ->
        do_count_acceptable(parts, workflows, total)

      {:redirect, target} ->
        do_count_acceptable(Workflow.apply(workflows[target], part) ++ parts, workflows, total)
    end
  end
end
