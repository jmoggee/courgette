# examples/storybook.exs
#
# Courgette Storybook — interactive showcase of every component.
#
# Sidebar navigation on the left, component preview on the right.
# Tab switches focus, arrow keys navigate, Enter selects, q quits.
#
# Run: mix run examples/storybook.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Components.{
  Checkbox,
  List,
  ProgressBar,
  RadioGroup,
  ScrollArea,
  Select,
  Spinner,
  Switch,
  Table,
  Tabs,
  Textarea,
  TextInput,
  Tree
}

# ────────────────────────────────────────────────────────────────
# Navigation items grouped by category
# ────────────────────────────────────────────────────────────────

defmodule Storybook.Nav do
  @items [
    # Form Controls
    {"checkbox", "  Checkbox"},
    {"switch", "  Switch"},
    {"radio_group", "  RadioGroup"},
    {"select", "  Select"},
    {"text_input", "  TextInput"},
    {"textarea", "  Textarea"},
    # Data Display
    {"table", "  Table"},
    {"list", "  List"},
    {"tree", "  Tree"},
    # Navigation
    {"tabs", "  Tabs"},
    # Feedback
    {"spinner", "  Spinner"},
    {"progress_bar", "  ProgressBar"},
    {"scrollbar", "  Scrollbar"},
    {"scroll_area", "  ScrollArea"},
    # Typography
    {"link", "  Link"},
    {"badge", "  Badge"},
    {"heading", "  Heading"},
    {"divider", "  Divider"},
    {"key_value", "  KeyValue"},
    # Lists & Layout
    {"ordered_list", "  OrderedList"},
    {"unordered_list", "  UnorderedList"},
    {"overlay", "  Overlay"},
    {"empty_state", "  EmptyState"}
  ]

  def items, do: @items

  # Category headers with their starting indices
  @categories [
    {0, "Form Controls"},
    {6, "Data Display"},
    {9, "Navigation"},
    {10, "Feedback"},
    {14, "Typography"},
    {19, "Lists & Layout"}
  ]

  def categories, do: @categories

  def category_for(index) do
    @categories
    |> Enum.reverse()
    |> Enum.find(fn {start, _} -> index >= start end)
    |> case do
      {_, name} -> name
      nil -> ""
    end
  end
end

# ────────────────────────────────────────────────────────────────
# Sidebar — custom LiveComponent with category headers
# ────────────────────────────────────────────────────────────────

defmodule Storybook.Sidebar do
  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    {:ok,
     assigns
     |> assign_new(:selected, fn -> 0 end)
     |> assign_new(:on_select, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def update(props, assigns) do
    {:ok, Map.merge(assigns, props)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white
    items = Storybook.Nav.items()
    category_starts = Map.new(Storybook.Nav.categories())

    box flex_direction: :column, border: :single, border_color: border_color do
      for {item, idx} <- Enum.with_index(items) do
        {_id, label} = item
        selected? = idx == assigns.selected

        [
          # Category header before this item if it starts a new category
          if Map.has_key?(category_starts, idx) do
            if idx > 0 do
              text(dim: true, do: "")
            end
          end,
          if Map.has_key?(category_starts, idx) do
            text bold: true, fg: :yellow do
              category_starts[idx]
            end
          end,
          # Nav item
          if selected? do
            text bold: true, fg: :cyan do
              "▸#{label}"
            end
          else
            text dim: true do
              " #{label}"
            end
          end
        ]
      end
    end
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    max_idx = length(Storybook.Nav.items()) - 1
    {:noreply, assign(assigns, :selected, min(assigns.selected + 1, max_idx))}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, assign(assigns, :selected, max(assigns.selected - 1, 0))}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_select && assigns.parent_pid do
      {id, _label} = Enum.at(Storybook.Nav.items(), assigns.selected)
      send(assigns.parent_pid, {assigns.on_select, id})
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end
end

# ────────────────────────────────────────────────────────────────
# Root App
# ────────────────────────────────────────────────────────────────

defmodule Storybook do
  use Courgette.App
  import Courgette.Components
  import Courgette.Components.Link
  import Courgette.Components.Scrollbar
  import Courgette.Components.Overlay
  import Courgette.Components.OrderedList
  import Courgette.Components.UnorderedList

  # ── Mount ────────────────────────────────────────────────────

  @impl true
  def mount(_assigns) do
    if Courgette.animations_enabled?() do
      Process.send_after(self(), :progress_tick, 50)
    end

    {:ok,
     %{
       current_page: "checkbox",

       # Form controls
       cb_terms: false,
       cb_subscribe: false,
       sw_dark: false,
       sw_notifications: true,
       radio_color: nil,
       select_value: nil,
       input_value: "",
       input_submitted: nil,
       textarea_value: "",
       autocomplete_suggestions: [],

       # Data display
       table_selected: nil,
       list_selected: nil,
       tree_selected: nil,

       # Navigation
       tabs_active: nil,

       # Feedback
       progress: 0.0,

       # Overlay / Command Palette
       palette_filter: "",
       palette_selected: nil
     }}
  end

  # ── Render ───────────────────────────────────────────────────

  @impl true
  def render(assigns) do
    box flex_direction: :column do
      # Header
      box flex_direction: :column, padding_h: 1 do
        text bold: true, fg: :cyan do
          "Courgette Storybook"
        end

        text dim: true do
          "Interactive component showcase"
        end
      end

      divider(color: :bright_black)

      # Body: sidebar + preview
      box flex_direction: :row, flex: 1 do
        # Sidebar
        box width: 26, flex_direction: :column do
          live_component(Storybook.Sidebar,
            id: "nav",
            focusable: true,
            on_select: :nav_select
          )
        end

        # Vertical separator
        box width: 1, flex_direction: :column do
          text dim: true, white_space: :nowrap do
            String.duplicate("│", 500)
          end
        end

        # Preview pane
        box flex_direction: :column, flex: 1, padding_h: 2 do
          render_page(assigns)
        end
      end

      # Footer
      divider(color: :bright_black)

      box padding_h: 1 do
        text dim: true do
          "Tab: switch focus  |  ↑↓: navigate  |  Enter: select  |  q: quit"
        end
      end
    end
  end

  # ── Page dispatch ────────────────────────────────────────────

  defp render_page(assigns) do
    case assigns.current_page do
      "checkbox" -> render_checkbox_page(assigns)
      "switch" -> render_switch_page(assigns)
      "radio_group" -> render_radio_group_page(assigns)
      "select" -> render_select_page(assigns)
      "text_input" -> render_text_input_page(assigns)
      "textarea" -> render_textarea_page(assigns)
      "table" -> render_table_page(assigns)
      "list" -> render_list_page(assigns)
      "tree" -> render_tree_page(assigns)
      "tabs" -> render_tabs_page(assigns)
      "spinner" -> render_spinner_page(assigns)
      "progress_bar" -> render_progress_bar_page(assigns)
      "scrollbar" -> render_scrollbar_page(assigns)
      "scroll_area" -> render_scroll_area_page(assigns)
      "link" -> render_link_page(assigns)
      "badge" -> render_badge_page(assigns)
      "heading" -> render_heading_page(assigns)
      "divider" -> render_divider_page(assigns)
      "key_value" -> render_key_value_page(assigns)
      "ordered_list" -> render_ordered_list_page(assigns)
      "unordered_list" -> render_unordered_list_page(assigns)
      "overlay" -> render_overlay_page(assigns)
      "empty_state" -> render_empty_state_page(assigns)
      _ -> render_checkbox_page(assigns)
    end
  end

  # ── Form Controls ───────────────────────────────────────────

  defp render_checkbox_page(assigns) do
    box flex_direction: :column do
      heading(text: "Checkbox", color: :cyan)

      text dim: true do
        "A toggleable boolean control. Focus and press Enter or Space to toggle."
      end

      box flex_direction: :column, padding_v: 1 do
        live_component(Checkbox,
          id: "cb_terms",
          focusable: true,
          checked: assigns.cb_terms,
          label: "Accept terms",
          on_change: :cb_terms_changed
        )

        live_component(Checkbox,
          id: "cb_subscribe",
          focusable: true,
          checked: assigns.cb_subscribe,
          label: "Subscribe to newsletter",
          on_change: :cb_subscribe_changed
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "terms", value: "#{assigns.cb_terms}")
      key_value(label: "subscribe", value: "#{assigns.cb_subscribe}")
    end
  end

  defp render_switch_page(assigns) do
    box flex_direction: :column do
      heading(text: "Switch", color: :cyan)

      text dim: true do
        "On/off toggle. Visual alternative to a checkbox."
      end

      box flex_direction: :column, padding_v: 1 do
        live_component(Switch,
          id: "sw_dark",
          focusable: true,
          on: assigns.sw_dark,
          label: "Dark mode",
          on_change: :sw_dark_changed
        )

        live_component(Switch,
          id: "sw_notifications",
          focusable: true,
          on: assigns.sw_notifications,
          label: "Notifications",
          on_change: :sw_notifications_changed
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "dark_mode", value: "#{assigns.sw_dark}")
      key_value(label: "notifications", value: "#{assigns.sw_notifications}")
    end
  end

  defp render_radio_group_page(assigns) do
    box flex_direction: :column do
      heading(text: "RadioGroup", color: :cyan)

      text dim: true do
        "Single-selection from a group of options."
      end

      box padding_v: 1 do
        live_component(RadioGroup,
          id: "radio_color",
          focusable: true,
          options: [
            {"red", "Red"},
            {"green", "Green"},
            {"blue", "Blue"},
            {"yellow", "Yellow"}
          ],
          selected: assigns.radio_color,
          on_change: :radio_color_changed,
          label: "Favorite color:"
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "selected", value: inspect(assigns.radio_color))
    end
  end

  defp render_select_page(assigns) do
    box flex_direction: :column do
      heading(text: "Select", color: :cyan)

      text dim: true do
        "Dropdown selector. Press Enter to expand, arrow keys to navigate, Enter to confirm."
      end

      box padding_v: 1 do
        live_component(Select,
          id: "select_color",
          focusable: true,
          options: [
            {"red", "Red"},
            {"green", "Green"},
            {"blue", "Blue"},
            {"cyan", "Cyan"},
            {"magenta", "Magenta"}
          ],
          on_select: :select_changed,
          prompt: "Pick a color:"
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "selected", value: inspect(assigns.select_value))
    end
  end

  defp render_text_input_page(assigns) do
    box flex_direction: :column do
      heading(text: "TextInput", color: :cyan)

      text dim: true do
        "Single-line text input. Type to edit, Enter to submit."
      end

      box padding_v: 1 do
        live_component(TextInput,
          id: "text_input",
          focusable: true,
          value: assigns.input_value,
          placeholder: "Type something...",
          on_change: :input_changed,
          on_submit: :input_submitted
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "value", value: inspect(assigns.input_value))
      key_value(label: "submitted", value: inspect(assigns.input_submitted))
    end
  end

  @demo_files [
    "lib/courgette.ex",
    "lib/courgette/app.ex",
    "lib/courgette/autocomplete.ex",
    "lib/courgette/component.ex",
    "lib/courgette/components/textarea.ex",
    "lib/courgette/components/select.ex",
    "lib/courgette/components/text_input.ex",
    "lib/courgette/renderer.ex",
    "lib/courgette/painter.ex",
    "lib/courgette/buffer.ex",
    "lib/courgette/layout/engine.ex",
    "lib/courgette/layout/engine/flex.ex",
    "mix.exs",
    "README.md"
  ]

  defp render_textarea_page(assigns) do
    box flex_direction: :column do
      heading(text: "Textarea", color: :cyan)

      text dim: true do
        "Multi-line text editor. Enter adds a new line."
      end

      box padding_v: 1, min_height: 8, width: 40 do
        live_component(Textarea,
          id: "textarea",
          focusable: true,
          value: assigns.textarea_value,
          placeholder: "Enter multi-line text...",
          on_change: :textarea_changed,
          height: 6
        )
      end

      heading(text: "State", color: :yellow, divider: false)

      key_value(
        label: "lines",
        value: "#{length(String.split(assigns.textarea_value, "\n"))}"
      )

      key_value(
        label: "chars",
        value: "#{String.length(assigns.textarea_value)}"
      )

      heading(text: "Autocomplete", color: :cyan)

      text dim: true do
        "Type @ to trigger file autocomplete. ↑↓ to navigate, Enter to accept, Esc to dismiss."
      end

      box padding_v: 1, min_height: 8, width: 50 do
        live_component(Textarea,
          id: "textarea_ac",
          focusable: true,
          placeholder: "Type @ to mention a file...",
          triggers: [%{char: "@", tag: :file_ref}],
          on_trigger: :ta_autocomplete,
          trigger_suggestions: assigns.autocomplete_suggestions,
          height: 6
        )
      end
    end
  end

  # ── Data Display ────────────────────────────────────────────

  defp render_table_page(assigns) do
    box flex_direction: :column do
      heading(text: "Table", color: :cyan)

      text dim: true do
        "Tabular data with row navigation. Arrow keys move, Enter selects."
      end

      box padding_v: 1 do
        live_component(Table,
          id: "table",
          focusable: true,
          columns: [
            [key: :id, header: "ID", align: :right],
            [key: :name, header: "Name"],
            [key: :role, header: "Role", align: :center],
            [key: :status, header: "Status"]
          ],
          rows: [
            %{id: 1, name: "Alice", role: "Engineer", status: "Active"},
            %{id: 2, name: "Bob", role: "Designer", status: "Away"},
            %{id: 3, name: "Carol", role: "PM", status: "Active"},
            %{id: 4, name: "Dave", role: "Engineer", status: "Offline"}
          ],
          on_select: :table_row_selected
        )
      end

      heading(text: "State", color: :yellow, divider: false)

      key_value(
        label: "selected",
        value:
          if(assigns.table_selected,
            do: "#{assigns.table_selected.name} (#{assigns.table_selected.role})",
            else: "none"
          )
      )
    end
  end

  defp render_list_page(assigns) do
    box flex_direction: :column do
      heading(text: "List", color: :cyan)

      text dim: true do
        "Scrollable navigable list. Supports highlight and select events."
      end

      box padding_v: 1 do
        live_component(List,
          id: "list",
          focusable: true,
          items: [
            {"elixir", "Elixir"},
            {"rust", "Rust"},
            {"go", "Go"},
            {"python", "Python"},
            {"typescript", "TypeScript"},
            {"ruby", "Ruby"},
            {"swift", "Swift"},
            {"kotlin", "Kotlin"}
          ],
          on_select: :list_item_selected,
          max_visible: 6
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "selected", value: inspect(assigns.list_selected))
    end
  end

  defp render_tree_page(assigns) do
    box flex_direction: :column do
      heading(text: "Tree", color: :cyan)

      text dim: true do
        "Expandable hierarchy. Tab to focus, ← collapses, → expands, Enter selects."
      end

      box padding_v: 1 do
        live_component(Tree,
          id: "tree",
          focusable: true,
          data: [
            {"lib",
             [
               {"courgette",
                [
                  "app.ex",
                  "component.ex",
                  {"components",
                   [
                     "checkbox.ex",
                     "select.ex",
                     "switch.ex"
                   ]},
                  "renderer.ex"
                ]}
             ]},
            {"test",
             [
               "courgette_test.exs"
             ]},
            "mix.exs",
            "README.md"
          ],
          expanded: MapSet.new([[0], [0, 0]]),
          on_select: :tree_node_selected
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "selected", value: inspect(assigns.tree_selected))
    end
  end

  # ── Navigation ──────────────────────────────────────────────

  defp render_tabs_page(assigns) do
    box flex_direction: :column do
      heading(text: "Tabs", color: :cyan)

      text dim: true do
        "Horizontal tab bar. Left/right arrows switch tabs, Enter confirms."
      end

      box padding_v: 1 do
        live_component(Tabs,
          id: "tabs",
          focusable: true,
          tabs: [
            {"overview", "Overview"},
            {"settings", "Settings"},
            {"logs", "Logs"},
            {"help", "Help"}
          ],
          on_change: :tabs_changed
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "active", value: inspect(assigns.tabs_active))
    end
  end

  # ── Feedback ────────────────────────────────────────────────

  @spinner_styles [
    # Braille family
    {:dots, "dots", :cyan},
    {:dots_pulse, "dots_pulse", :cyan},
    {:dots_orbit, "dots_orbit", :cyan},
    {:dots_scroll, "dots_scroll", :cyan},
    {:dots_bounce, "dots_bounce", :cyan},
    {:sand, "sand", :cyan},
    {:braille_double, "braille_double", :cyan},
    {:braille_six, "braille_six", :cyan},
    {:braille_eight_double, "braille_eight_double", :cyan},
    # Geometric family
    {:circle, "circle", :green},
    {:arc, "arc", :green},
    {:triangle, "triangle", :green},
    {:quarter, "quarter", :green},
    {:box_bounce, "box_bounce", :green},
    {:pipe, "pipe", :green},
    {:box_invert, "box_invert", :green},
    {:square_corners, "square_corners", :green},
    # Block family
    {:wave, "wave", :yellow},
    {:pulse, "pulse", :yellow},
    {:meter, "meter", :yellow},
    {:grow_horizontal, "grow_horizontal", :yellow},
    {:noise, "noise", :yellow},
    {:layer, "layer", :yellow},
    # Classic
    {:line, "line", :magenta},
    {:star, "star", :magenta},
    {:point, "point", :magenta},
    {:bounce, "bounce", :magenta},
    {:arrow, "arrow", :magenta},
    {:ellipsis, "ellipsis", :magenta},
    {:hamburger, "hamburger", :magenta}
  ]

  defp render_spinner_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Spinner", color: :cyan)

      text dim: true do
        "Animated loading indicator. 30 built-in styles."
      end

      box flex_direction: :column, padding_v: 1 do
        text bold: true, fg: :cyan do
          "Braille"
        end

        for {style, label, color} <- Enum.slice(@spinner_styles, 0, 9) do
          live_component(Spinner,
            id: "sp_#{label}",
            style: style,
            label: label,
            color: color
          )
        end

        text bold: true, fg: :green do
          "Geometric"
        end

        for {style, label, color} <- Enum.slice(@spinner_styles, 9, 8) do
          live_component(Spinner,
            id: "sp_#{label}",
            style: style,
            label: label,
            color: color
          )
        end

        text bold: true, fg: :yellow do
          "Block"
        end

        for {style, label, color} <- Enum.slice(@spinner_styles, 17, 6) do
          live_component(Spinner,
            id: "sp_#{label}",
            style: style,
            label: label,
            color: color
          )
        end

        text bold: true, fg: :magenta do
          "Classic"
        end

        for {style, label, color} <- Enum.slice(@spinner_styles, 23, 7) do
          live_component(Spinner,
            id: "sp_#{label}",
            style: style,
            label: label,
            color: color
          )
        end
      end
    end
  end

  defp render_progress_bar_page(assigns) do
    pct = round(assigns.progress * 100)

    box flex_direction: :column do
      heading(text: "ProgressBar", color: :cyan)

      text dim: true do
        "Determinate progress indicator. Value driven by parent."
      end

      box flex_direction: :column, padding_v: 1 do
        live_component(ProgressBar,
          id: "pb_green",
          value: assigns.progress,
          width: 30,
          color: :green,
          label: :percent
        )

        live_component(ProgressBar,
          id: "pb_cyan",
          value: min(assigns.progress + 0.2, 1.0),
          width: 30,
          color: :cyan,
          label: :percent
        )

        live_component(ProgressBar,
          id: "pb_yellow",
          value: min(assigns.progress + 0.4, 1.0),
          width: 30,
          color: :yellow,
          label: :percent
        )
      end

      heading(text: "State", color: :yellow, divider: false)
      key_value(label: "progress", value: "#{pct}%")
    end
  end

  defp render_scrollbar_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Scrollbar", color: :cyan)

      text dim: true do
        "Visual scroll position indicator. Pure function component."
      end

      box flex_direction: :column, padding_v: 1 do
        text do
          "Vertical (top):"
        end

        box flex_direction: :row, height: 8 do
          box border: :single, width: 20, height: 8 do
            text do
              "Content area"
            end
          end

          scrollbar(
            content_length: 100,
            viewport_length: 20,
            offset: 0,
            orientation: :vertical
          )
        end

        text do
          "Vertical (middle):"
        end

        box flex_direction: :row, height: 8 do
          box border: :single, width: 20, height: 8 do
            text do
              "Content area"
            end
          end

          scrollbar(
            content_length: 100,
            viewport_length: 20,
            offset: 40,
            orientation: :vertical
          )
        end
      end
    end
  end

  defp render_scroll_area_page(_assigns) do
    lines = for i <- 1..30, do: "Line #{i}: Lorem ipsum dolor sit amet"

    box flex_direction: :column do
      heading(text: "ScrollArea", color: :cyan)

      text dim: true do
        "Scrollable viewport with automatic scrollbar. Focus and use ↑↓ / PgUp/PgDn / Home/End."
      end

      box flex_direction: :column, padding_v: 1 do
        live_component(ScrollArea,
          id: "scroll_demo",
          height: 10,
          focusable: true,
          border: :single,
          inner_block: build_scroll_lines(lines)
        )
      end
    end
  end

  defp build_scroll_lines(lines) do
    import Courgette.Component.DSL

    for {line, idx} <- Enum.with_index(lines) do
      color = if rem(idx, 2) == 0, do: :white, else: :bright_black

      text fg: color do
        line
      end
    end
  end

  # ── Typography ──────────────────────────────────────────────

  defp render_link_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Link", color: :cyan)

      text dim: true do
        "Styled hyperlink text. Underlined with configurable color."
      end

      box flex_direction: :column, padding_v: 1 do
        link(label: "Courgette on GitHub", url: "https://github.com/loam/courgette")
        link(label: "Elixir Docs", url: "https://hexdocs.pm/elixir", color: :green)
        link(label: "Hex.pm", url: "https://hex.pm", color: :yellow)
      end
    end
  end

  defp render_badge_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Badge", color: :cyan)

      text dim: true do
        "Colored label badges for status, tags, and categories."
      end

      box flex_direction: :column, padding_v: 1 do
        box flex_direction: :row do
          badge(label: "OK", color: :green)
          badge(label: "Warning", color: :yellow)
          badge(label: "Error", color: :red)
          badge(label: "Info", color: :cyan)
        end

        box flex_direction: :row do
          badge(label: "v1.0", color: :blue)
          badge(label: "beta", color: :magenta)
          badge(label: "new", color: :green)
          badge(label: "deprecated", color: :bright_black)
        end
      end
    end
  end

  defp render_heading_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Heading", color: :cyan)

      text dim: true do
        "Section header with optional divider line."
      end

      box flex_direction: :column, padding_v: 1 do
        heading(text: "Default (with divider)", color: :cyan)
        heading(text: "Without divider", color: :green, divider: false)
        heading(text: "Yellow heading", color: :yellow)
        heading(text: "Magenta heading", color: :magenta)
      end
    end
  end

  defp render_divider_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Divider", color: :cyan)

      text dim: true do
        "Horizontal rule for visual separation."
      end

      box flex_direction: :column, padding_v: 1 do
        text do
          "Section one content"
        end

        divider([])

        text do
          "Section two content"
        end

        divider(color: :cyan)

        text do
          "Section three content"
        end

        divider(color: :yellow)

        text do
          "Section four content"
        end
      end
    end
  end

  defp render_key_value_page(_assigns) do
    box flex_direction: :column do
      heading(text: "KeyValue", color: :cyan)

      text dim: true do
        "Label-value pairs for displaying metadata."
      end

      box flex_direction: :column, padding_v: 1 do
        key_value(label: "Name", value: "Courgette")
        key_value(label: "Version", value: "0.1.0")
        key_value(label: "Language", value: "Elixir")
        key_value(label: "License", value: "MIT")
        key_value(label: "Dependencies", value: "0 (runtime)")
      end
    end
  end

  # ── Lists & Layout ──────────────────────────────────────────

  defp render_ordered_list_page(_assigns) do
    box flex_direction: :column do
      heading(text: "OrderedList", color: :cyan)

      text dim: true do
        "Numbered list items. Configurable start number and color."
      end

      box flex_direction: :column, padding_v: 1 do
        text bold: true do
          "Steps:"
        end

        ordered_list(
          items: [
            "Create a new Elixir project",
            "Add Courgette as a dependency",
            "Define your App module",
            "Run with mix run"
          ],
          color: :cyan
        )

        text bold: true do
          "Starting at 5:"
        end

        ordered_list(
          items: ["Fifth item", "Sixth item", "Seventh item"],
          start: 5,
          color: :green
        )
      end
    end
  end

  defp render_unordered_list_page(_assigns) do
    box flex_direction: :column do
      heading(text: "UnorderedList", color: :cyan)

      text dim: true do
        "Bulleted list. Configurable marker and color."
      end

      box flex_direction: :column, padding_v: 1 do
        text bold: true do
          "Default marker:"
        end

        unordered_list(
          items: ["Checkbox", "Switch", "RadioGroup", "Select"],
          color: :cyan
        )

        text bold: true do
          "Custom marker:"
        end

        unordered_list(
          items: ["Table", "List", "Tree"],
          marker: "→",
          color: :green
        )

        text bold: true do
          "Dash marker:"
        end

        unordered_list(
          items: ["Spinner", "ProgressBar"],
          marker: "-",
          color: :yellow
        )
      end
    end
  end

  @palette_items Enum.map(Storybook.Nav.items(), fn {id, label} ->
                   {id, String.trim(label)}
                 end)

  defp render_overlay_page(_assigns) do
    box flex_direction: :column do
      heading(text: "Overlay", color: :cyan)

      text dim: true do
        "Testing the overlay component with static content."
      end

      box padding_v: 1, flex: 1 do
        overlay(
          title: "Simple Overlay",
          width: 40,
          do: [
            text(do: "Line one"),
            text(do: "Line two"),
            text(fg: :cyan, do: "Line three (cyan)")
          ]
        )
      end
    end
  end

  defp render_empty_state_page(_assigns) do
    box flex_direction: :column do
      heading(text: "EmptyState", color: :cyan)

      text dim: true do
        "Placeholder for empty content areas."
      end

      box flex_direction: :column, padding_v: 1 do
        box border: :rounded, height: 5 do
          empty_state(message: "No items found")
        end

        box border: :rounded, height: 5 do
          empty_state(message: "No results match your search")
        end

        box border: :rounded, height: 5 do
          empty_state(message: "Nothing here yet. Create your first item!")
        end
      end
    end
  end

  # ── Event Handlers ──────────────────────────────────────────

  @impl true
  def handle_event({:key, {:char, "q"}}, assigns) do
    Courgette.stop()
    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # ── Info Handlers ───────────────────────────────────────────

  @impl true
  def handle_info({:nav_select, page}, assigns) do
    {:noreply, assign(assigns, :current_page, page)}
  end

  # Form controls
  def handle_info({:cb_terms_changed, value}, assigns) do
    {:noreply, assign(assigns, :cb_terms, value)}
  end

  def handle_info({:cb_subscribe_changed, value}, assigns) do
    {:noreply, assign(assigns, :cb_subscribe, value)}
  end

  def handle_info({:sw_dark_changed, value}, assigns) do
    {:noreply, assign(assigns, :sw_dark, value)}
  end

  def handle_info({:sw_notifications_changed, value}, assigns) do
    {:noreply, assign(assigns, :sw_notifications, value)}
  end

  def handle_info({:radio_color_changed, value}, assigns) do
    {:noreply, assign(assigns, :radio_color, value)}
  end

  def handle_info({:select_changed, value}, assigns) do
    {:noreply, assign(assigns, :select_value, value)}
  end

  def handle_info({:input_changed, value}, assigns) do
    {:noreply, assign(assigns, :input_value, value)}
  end

  def handle_info({:input_submitted, value}, assigns) do
    {:noreply, assign(assigns, :input_submitted, value)}
  end

  def handle_info({:textarea_changed, value}, assigns) do
    {:noreply, assign(assigns, :textarea_value, value)}
  end

  def handle_info({:ta_autocomplete, %{accepted: true}}, assigns) do
    {:noreply, assign(assigns, :autocomplete_suggestions, [])}
  end

  def handle_info({:ta_autocomplete, %{tag: :file_ref, query: q}}, assigns) do
    matches =
      @demo_files
      |> Enum.filter(&String.contains?(&1, q))
      |> Enum.take(8)

    Courgette.send_update(Textarea, id: "textarea_ac", trigger_suggestions: matches)
    {:noreply, assigns}
  end

  # Command palette
  def handle_info({:palette_filter_changed, value}, assigns) do
    {:noreply, assign(assigns, :palette_filter, value)}
  end

  def handle_info({:palette_selected, id}, assigns) do
    {:noreply, assign(assigns, :palette_selected, id)}
  end

  # Data display
  def handle_info({:table_row_selected, row}, assigns) do
    {:noreply, assign(assigns, :table_selected, row)}
  end

  def handle_info({:list_item_selected, id}, assigns) do
    {:noreply, assign(assigns, :list_selected, id)}
  end

  def handle_info({:tree_node_selected, label}, assigns) do
    {:noreply, assign(assigns, :tree_selected, label)}
  end

  # Navigation
  def handle_info({:tabs_changed, value}, assigns) do
    {:noreply, assign(assigns, :tabs_active, value)}
  end

  # Progress animation tick
  def handle_info(:progress_tick, assigns) do
    new_progress = assigns.progress + 0.005

    new_progress =
      if new_progress > 1.0, do: 0.0, else: new_progress

    if Courgette.animations_enabled?() do
      Process.send_after(self(), :progress_tick, 50)
    end

    {:noreply, assign(assigns, :progress, new_progress)}
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

# ── Entry point ──────────────────────────────────────────────

Courgette.run(Storybook)
