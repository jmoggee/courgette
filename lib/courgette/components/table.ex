defmodule Courgette.Components.Table do
  @moduledoc """
  Tabular data display with row navigation and per-column alignment.

  Renders a bordered table with column headers, a separator line, and
  data rows. Each cell is a layout box with explicit width and alignment,
  so the flexbox engine handles column sizing. Arrow keys navigate between
  rows and Enter confirms a selection. Notifies the parent via
  `send(assigns.parent_pid, {on_select, row_map})` when confirmed.

  ## Props

  - `columns` — list of column definitions, each a keyword list:
    - `:key` — (required) map key for data lookup
    - `:header` — (required) display text for the column header
    - `:align` — `:left` (default), `:center`, or `:right`
    - `:width` — explicit column width (default `:auto`, sized to content)
  - `rows` — list of maps with data keyed by column keys.
  - `selected` — initially selected row index (default 0).
  - `on_select` — message tag sent to parent on Enter (optional).

  ## Example

      live_component(Table,
        id: "users",
        focusable: true,
        columns: [
          [key: :id, header: "ID", align: :right],
          [key: :name, header: "Name"],
          [key: :role, header: "Role", align: :center],
          [key: :status, header: "Status", width: 12]
        ],
        rows: [
          %{id: 1, name: "Alice", role: "Engineer", status: "Active"},
          %{id: 2, name: "Bob", role: "Designer", status: "Away"}
        ],
        on_select: :row_selected
      )
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    columns = normalize_columns(assigns[:columns] || [])

    {:ok,
     assigns
     |> assign(:columns, columns)
     |> assign_new(:rows, fn -> [] end)
     |> assign_new(:selected, fn -> 0 end)
     |> assign_new(:on_select, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white
    columns = assigns.columns
    rows = assigns.rows
    widths = column_widths(columns, rows)

    box border: :single, border_color: border_color, flex_direction: :column do
      # Header row
      render_row(columns, widths, "  ", fn col -> col.header end, bold: true)

      # Separator
      text do
        "  " <> separator_line(widths)
      end

      # Data rows
      for {row, idx} <- Enum.with_index(rows) do
        render_data_row(row, idx, assigns.selected, columns, widths)
      end
    end
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :columns) do
        assign(new_assigns, :columns, normalize_columns(props.columns))
      else
        new_assigns
      end

    {:ok, new_assigns}
  end

  @impl true
  def handle_event(:focus, assigns) do
    {:noreply, assign(assigns, :focused, true)}
  end

  def handle_event(:blur, assigns) do
    {:noreply, assign(assigns, :focused, false)}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    max_idx = max(length(assigns.rows) - 1, 0)
    {:noreply, assign(assigns, :selected, min(assigns.selected + 1, max_idx))}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, assign(assigns, :selected, max(assigns.selected - 1, 0))}
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_select && assigns.parent_pid do
      row = Enum.at(assigns.rows, assigns.selected)

      if row do
        send(assigns.parent_pid, {assigns.on_select, row})
      end
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # -- Private helpers --

  defp render_data_row(row, idx, selected_idx, columns, widths) do
    if idx == selected_idx do
      render_row(columns, widths, "▸ ", fn col -> cell_value(row, col.key) end,
        bold: true,
        fg: :cyan
      )
    else
      render_row(columns, widths, "  ", fn col -> cell_value(row, col.key) end, [])
    end
  end

  defp render_row(columns, widths, prefix, value_fn, style) do
    box flex_direction: :row do
      text Keyword.merge(style, []) do
        prefix
      end

      columns
      |> Enum.zip(widths)
      |> Enum.with_index()
      |> Enum.flat_map(fn {{col, width}, idx} ->
        cell = render_cell(value_fn.(col), width, col.align, style)

        if idx > 0 do
          separator =
            text Keyword.merge(style, []) do
              " │ "
            end

          [separator, cell]
        else
          [cell]
        end
      end)
    end
  end

  defp render_cell(value, width, align, style) do
    justify = alignment_to_justify(align)

    box width: width, justify_content: justify do
      text Keyword.merge(style, []) do
        value
      end
    end
  end

  defp alignment_to_justify(:left), do: :flex_start
  defp alignment_to_justify(:center), do: :center
  defp alignment_to_justify(:right), do: :flex_end

  defp normalize_columns(columns) do
    Enum.map(columns, fn col when is_list(col) ->
      %{
        key: Keyword.fetch!(col, :key),
        header: Keyword.fetch!(col, :header),
        align: Keyword.get(col, :align, :left),
        width: Keyword.get(col, :width, :auto)
      }
    end)
  end

  defp column_widths(columns, rows) do
    Enum.map(columns, fn col ->
      header_width = String.length(to_string(col.header))

      max_cell =
        rows
        |> Enum.map(fn row -> String.length(cell_value(row, col.key)) end)
        |> Enum.max(fn -> 0 end)

      auto_width = max(header_width, max_cell)

      case col.width do
        :auto -> auto_width
        explicit when is_integer(explicit) -> max(explicit, header_width)
      end
    end)
  end

  defp cell_value(row, key) when is_map(row) do
    value =
      Map.get(row, key) ||
        atom_key_lookup(row, key)

    to_string(value || "")
  end

  defp atom_key_lookup(row, key) when is_binary(key) do
    Map.get(row, String.to_existing_atom(key))
  rescue
    ArgumentError -> nil
  end

  defp atom_key_lookup(row, key) when is_atom(key) do
    Map.get(row, Atom.to_string(key))
  end

  defp atom_key_lookup(_row, _key), do: nil

  defp separator_line(widths) do
    Enum.map_join(widths, "─┼─", fn w -> String.duplicate("─", w) end)
  end
end
