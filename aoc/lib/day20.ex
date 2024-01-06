defmodule Day20 do
  defmodule PulseCounter do
    use Agent

    def start_link(),
      do: Agent.start_link(fn -> %{low: 0, high: 0, button: 0} end, name: __MODULE__)

    def send(pulse) when pulse in [:low, :high, :button],
      do:
        Agent.update(__MODULE__, fn map ->
          Map.update(map, pulse, 1, &(&1 + 1))
        end)

    def score(), do: Agent.get(__MODULE__, fn map -> map |> Map.values() |> Enum.product() end)

    def presses(), do: Agent.get(__MODULE__, fn map -> map[:button] end)

    def stop, do: Agent.stop(__MODULE__)
  end

  defmodule Message do
    @enforce_keys [:from, :to, :value]
    defstruct [:from, :to, :value]
  end

  defmodule Module do
    @enforce_keys [:name, :type]
    defstruct([:name, :type, state: %{}, outputs: [], reporter: false])

    use Agent

    def start_link(:button, _name, _inputs, _outputs, _reporter) do
      Agent.start_link(fn -> %Module{name: :button, type: :button, outputs: [:broadcaster]} end,
        name: :button
      )
    end

    def start_link(:broadcaster, _name, _inputs, outputs, _reporter) do
      Agent.start_link(
        fn -> %Module{name: :broadcaster, type: :broadcaster, outputs: outputs} end,
        name: :broadcaster
      )
    end

    def start_link(:flipflop, name, _inputs, outputs, _reporter) do
      Agent.start_link(
        fn ->
          %Module{name: name, type: :flipflop, state: %{self: :off}, outputs: outputs}
        end,
        name: name
      )
    end

    def start_link(:conjunction, name, inputs, outputs, reporter) do
      Agent.start_link(
        fn ->
          %Module{
            name: name,
            type: :conjunction,
            state: inputs |> Map.from_keys(:low),
            outputs: outputs,
            reporter: reporter
          }
        end,
        name: name
      )
    end

    def start_link(_type, name, _inputs, _outputs, _reporter) do
      Agent.start_link(fn -> %Module{name: name, type: :other} end, name: name)
    end

    def stop(name), do: Agent.stop(name)

    def call(%Message{} = message),
      do:
        Agent.get_and_update(message.to, fn %Module{} = module ->
          case module.type do
            :button ->
              {[%Message{from: :button, to: :broadcaster, value: :low}], module}

            :broadcaster ->
              {module.outputs
               |> Enum.map(&%Message{from: :broadcaster, to: &1, value: message.value}), module}

            :flipflop ->
              case {module.state.self, message.value} do
                {_, :high} ->
                  {[], module}

                {:off, :low} ->
                  {module.outputs |> Enum.map(&%Message{from: module.name, to: &1, value: :high}),
                   %{module | state: %{self: :on}}}

                {:on, :low} ->
                  {module.outputs |> Enum.map(&%Message{from: module.name, to: &1, value: :low}),
                   %{module | state: %{self: :off}}}
              end

            :conjunction ->
              new_state = %{module.state | message.from => message.value}

              if new_state |> Map.values() |> Enum.all?(fn v -> v == :high end) do
                {module.outputs |> Enum.map(&%Message{from: module.name, to: &1, value: :low}),
                 %{module | state: new_state}}
              else
                if module.reporter, do: IO.inspect({module.name, PulseCounter.presses()})

                {module.outputs |> Enum.map(&%Message{from: module.name, to: &1, value: :high}),
                 %{module | state: new_state}}
              end

            :other ->
              {[], module}
          end
        end)
  end

  def part1(file) do
    PulseCounter.start_link()
    {:ok, pid} = file |> parse() |> Supervisor.start_link(strategy: :one_for_all)

    for _ <- 1..1000, do: run()
    PulseCounter.score() |> IO.inspect()

    Supervisor.stop(pid)
    PulseCounter.stop()
  end

  def part2(file) do
    PulseCounter.start_link()
    {:ok, pid} = file |> parse() |> Supervisor.start_link(strategy: :one_for_all)

    for _ <- 1..10_000, do: run()

    Supervisor.stop(pid)
    PulseCounter.stop()
  end

  defp parse(file), do: file |> AOCUtil.lines!() |> Enum.map(&parse_line/1) |> init()

  defp parse_line(line) do
    case(Regex.run(~r/^([%&]?)(.*) -> (.*)$/, line, capture: :all_but_first)) do
      ["", "broadcaster", outputs] ->
        {:broadcaster, :broadcaster, outputs |> String.split(", ") |> Enum.map(&String.to_atom/1)}

      ["%", name, outputs] ->
        {
          :flipflop,
          name |> String.to_atom(),
          outputs |> String.split(", ") |> Enum.map(&String.to_atom/1)
        }

      ["&", name, outputs] ->
        {
          :conjunction,
          name |> String.to_atom(),
          outputs |> String.split(", ") |> Enum.map(&String.to_atom/1)
        }
    end
  end

  defp init(specs) do
    inputs =
      specs
      |> Enum.reduce(%{}, fn {_, name, outputs}, acc ->
        outputs
        |> Map.from_keys([name])
        |> Map.merge(acc, fn _k, v1, v2 ->
          v1 ++ v2
        end)
      end)

    unknown =
      inputs
      |> Map.keys()
      |> MapSet.new()
      |> MapSet.difference(specs |> Enum.map(&elem(&1, 1)) |> MapSet.new())

    [to_spec(:button, :button, [], [:broadcaster])] ++
      (unknown |> Enum.map(&to_spec(:unknown, &1, inputs[&1], []))) ++
      (specs
       |> Enum.map(fn {type, name, outputs} ->
         to_spec(type, name, inputs[name], outputs, :sq in outputs)
       end))
  end

  defp to_spec(type, name, inputs, outputs, reporter \\ false),
    do: %{
      id: name,
      start: {Module, :start_link, [type, name, inputs, outputs, reporter]},
      modules: [Module]
    }

  defp run(), do: do_run(Qex.new([%Message{from: :actor, to: :button, value: :button}]))

  defp do_run(queue) do
    case Qex.pop(queue) do
      {:empty, _} ->
        :ok

      {{:value, message}, queue} ->
        PulseCounter.send(message.value)
        do_run(Qex.join(queue, Qex.new(Module.call(message))))
    end
  end
end
