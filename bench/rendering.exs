# Rendering pipeline benchmarks for Courgette.
# Measures each pipeline stage independently across four UI complexity scenarios.
#
# Run with: mix run bench/rendering.exs
# Estimated runtime: ~7 minutes

alias Courgette.{Buffer, Element, Painter}
alias Courgette.Buffer.{Diff, Writer}
alias Courgette.Layout.{Bounds, Engine}

defmodule Bench.Trees do
  @moduledoc false

  alias Courgette.Element

  @doc "Bordered status panel (~10 elements)"
  def small do
    Element.new(:box, [width: 40, height: 12, border: :single, padding: 1], [
      Element.new(:text, [bold: true, color: :cyan], ["System Status"]),
      Element.new(:text, [], ["Status: Online"]),
      Element.new(:text, [], ["Uptime: 42h 17m"]),
      Element.new(:text, [], ["CPU: 23%"]),
      Element.new(:text, [], ["Memory: 1.2 GB"]),
      Element.new(:text, [], ["Disk: 48% used"]),
      Element.new(:text, [], ["Network: eth0"]),
      Element.new(:text, [], ["Temp: 42C"])
    ])
  end

  @doc "Sidebar + form layout (~80 elements)"
  def medium do
    sidebar =
      Element.new(:box, [width: 20, border: :single, padding: 1], [
        Element.new(:text, [bold: true, color: :yellow], ["Navigation"]),
        Element.new(:text, [], ["Dashboard"]),
        Element.new(:text, [], ["Users"]),
        Element.new(:text, [], ["Settings"]),
        Element.new(:text, [], ["Logs"]),
        Element.new(:text, [], ["Help"])
      ])

    field_rows =
      for i <- 1..18 do
        Element.new(:box, [flex_direction: :row, gap: 2], [
          Element.new(:text, [width: 15, bold: true], ["Field #{i}:"]),
          Element.new(:box, [flex: 1, border: :single], [
            Element.new(:text, [], ["Value #{i}"])
          ])
        ])
      end

    form =
      Element.new(:box, [flex: 1, padding: 1], [
        Element.new(:text, [bold: true, color: :green], ["Edit Form"]) | field_rows
      ])

    Element.new(:box, [width: 80, height: 30, flex_direction: :row], [sidebar, form])
  end

  @doc "90-row data table (~1000 elements)"
  def large do
    header_row =
      Element.new(
        :box,
        [flex_direction: :row, bold: true, bg: :blue, color: :white],
        for header <- ["ID", "Name", "Email", "Role", "Status"] do
          Element.new(:box, [flex: 1, padding_h: 1], [
            Element.new(:text, [], [header])
          ])
        end
      )

    data_rows =
      for i <- 1..90 do
        bg = if rem(i, 2) == 0, do: [bg: {40, 40, 40}], else: []

        Element.new(
          :box,
          [flex_direction: :row] ++ bg,
          for c <- 1..5 do
            Element.new(:box, [flex: 1, padding_h: 1], [
              Element.new(:text, [], ["R#{i}C#{c}"])
            ])
          end
        )
      end

    Element.new(:box, [width: 120, height: 100, border: :single], [header_row | data_rows])
  end

  @doc "8-level nested boxes (~25 elements, tests recursive layout)"
  def deep do
    Enum.reduce(8..1//-1, Element.new(:text, [color: :green], ["Innermost"]), fn level, inner ->
      Element.new(:box, [border: :single], [
        Element.new(:text, [bold: true], ["Level #{level}"]),
        Element.new(:text, [color: :cyan], ["Depth info"]),
        inner
      ])
    end)
  end
end

defmodule Bench.Helpers do
  @moduledoc false

  alias Courgette.Element

  def count_elements(%Element{children: children}) do
    1 +
      Enum.sum(
        Enum.map(children, fn
          %Element{} = child -> count_elements(child)
          _string -> 0
        end)
      )
  end

  def put_in_first_text(%Element{type: :text} = el, new_text) do
    %{el | children: [new_text]}
  end

  def put_in_first_text(%Element{children: [%Element{} = first | rest]} = el, new_text) do
    %{el | children: [put_in_first_text(first, new_text) | rest]}
  end

  def put_in_first_text(el, _new_text), do: el
end

defmodule Bench.Fixtures do
  @moduledoc false

  alias Courgette.{Buffer, Painter}
  alias Courgette.Buffer.Diff
  alias Courgette.Layout.{Bounds, Engine}

  def build(tree, width, height) do
    bounds = Bounds.new(0, 0, width, height)
    layout_tree = Engine.compute(tree, bounds)
    empty_buffer = Buffer.new(width, height)
    painted_buffer = Painter.paint(layout_tree, empty_buffer)

    changed_tree = Bench.Helpers.put_in_first_text(tree, "CHANGED")
    changed_layout = Engine.compute(changed_tree, bounds)
    changed_buffer = Painter.paint(changed_layout, Buffer.new(width, height))

    full_diff_runs = Diff.diff(empty_buffer, painted_buffer)

    %{
      tree: tree,
      bounds: bounds,
      layout_tree: layout_tree,
      empty_buffer: empty_buffer,
      painted_buffer: painted_buffer,
      changed_buffer: changed_buffer,
      full_diff_runs: full_diff_runs
    }
  end
end

# --- Build fixtures ---

IO.puts("Building benchmark fixtures...\n")

scenarios = [
  {"small", Bench.Trees.small(), 40, 12},
  {"medium", Bench.Trees.medium(), 80, 30},
  {"large", Bench.Trees.large(), 120, 100},
  {"deep", Bench.Trees.deep(), 80, 40}
]

fixtures =
  Map.new(scenarios, fn {name, tree, w, h} ->
    IO.puts("  #{name}: #{Bench.Helpers.count_elements(tree)} elements (#{w}x#{h})")
    {name, Bench.Fixtures.build(tree, w, h)}
  end)

timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d_%H%M%S")
report_dir = "bench/reports/#{timestamp}"
File.mkdir_p!(report_dir)

formatters = [
  Benchee.Formatters.Console,
  {Benchee.Formatters.HTML, file: "#{report_dir}/layout.html", auto_open: false}
]

benchee_opts = [warmup: 2, time: 5, memory_time: 2, inputs: fixtures, formatters: formatters]

suites = [
  {"layout", "Layout",
   %{"Engine.compute" => fn fix -> Engine.compute(fix.tree, fix.bounds) end}},
  {"paint", "Paint",
   %{"Painter.paint" => fn fix -> Painter.paint(fix.layout_tree, fix.empty_buffer) end}},
  {"diff", "Diff",
   %{
     "no change" => fn fix -> Diff.diff(fix.painted_buffer, fix.painted_buffer) end,
     "small change" => fn fix -> Diff.diff(fix.painted_buffer, fix.changed_buffer) end,
     "full redraw" => fn fix -> Diff.diff(fix.empty_buffer, fix.painted_buffer) end
   }},
  {"writer", "Writer",
   %{"Writer.render" => fn fix -> Writer.render(fix.full_diff_runs) end}},
  {"full_pipeline", "Full Pipeline",
   %{
     "element → iodata" => fn fix ->
       layout_tree = Engine.compute(fix.tree, fix.bounds)
       painted = Painter.paint(layout_tree, fix.empty_buffer)
       runs = Diff.diff(fix.empty_buffer, painted)
       Writer.render(runs)
     end
   }}
]

results =
  for {file, title, scenarios} <- suites do
    IO.puts("\n━━━ #{title} ━━━\n")

    opts =
      Keyword.put(benchee_opts, :formatters, [
        Benchee.Formatters.Console,
        {Benchee.Formatters.HTML, file: "#{report_dir}/#{file}.html", auto_open: false}
      ])

    suite = Benchee.run(scenarios, opts)

    for scenario <- suite.scenarios do
      %{
        suite: file,
        name: scenario.name,
        input: scenario.input_name,
        ips: Float.round(scenario.run_time_data.statistics.ips, 2),
        average_us: Float.round(scenario.run_time_data.statistics.average / 1000, 2),
        median_us: Float.round(scenario.run_time_data.statistics.median / 1000, 2),
        deviation: Float.round(scenario.run_time_data.statistics.std_dev_ratio * 100, 2),
        memory_kb:
          if(scenario.memory_usage_data.statistics.average,
            do: Float.round(scenario.memory_usage_data.statistics.average / 1024, 2),
            else: nil
          )
      }
    end
  end

# Save snapshot for tracking over time
snapshot_dir = "bench/snapshots"
File.mkdir_p!(snapshot_dir)

snapshot = %{
  timestamp: DateTime.to_iso8601(DateTime.utc_now()),
  elixir: System.version(),
  otp: System.otp_release(),
  results: List.flatten(results)
}

snapshot_file = "#{snapshot_dir}/#{timestamp}.json"
File.write!(snapshot_file, Jason.encode!(snapshot, pretty: true))

IO.puts("\nHTML reports saved to #{report_dir}/")
IO.puts("Snapshot saved to #{snapshot_file}")
