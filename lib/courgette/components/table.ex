defmodule Courgette.Components.Table do
  @moduledoc """
  Tabular data display with row navigation.

  Renders a bordered table with column headers, a separator line, and
  data rows. Arrow keys navigate between rows and Enter confirms a
  selection. Notifies the parent via
  `send(assigns.parent_pid, {on_select, row_map})` when confirmed.

  ## Props

  - `columns` — list of column definitions. Each is a string (used as
    both key and header) or `{key, header}` tuple.
  - `rows` — list of maps with data keyed by column keys.
  - `selected` — initially selected row index (default 0).
  - `on_select` — message tag sent to parent on Enter (optional).
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

    box border: :single, border_color: border_color do
      # Header row
      text bold: true do
        format_row_cells(columns, widths, fn {_key, header} -> header end)
      end

      # Separator
      text do
        separator_line(widths)
      end

      # Data rows
      for {row, idx} <- Enum.with_index(rows) do
        selected? = idx == assigns.selected

        if selected? do
          text bold: true, fg: :cyan do
            "▸ " <>
              format_row_cells(columns, widths, fn {key, _header} -> cell_value(row, key) end)
          end
        else
          text do
            "  " <>
              format_row_cells(columns, widths, fn {key, _header} -> cell_value(row, key) end)
          end
        end
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

  defp normalize_columns(columns) do
    Enum.map(columns, fn
      {key, header} -> {key, header}
      str when is_binary(str) -> {str, str}
    end)
  end

  defp column_widths(columns, rows) do
    Enum.map(columns, fn {key, header} ->
      header_width = String.length(to_string(header))

      max_cell =
        rows
        |> Enum.map(fn row -> String.length(cell_value(row, key)) end)
        |> Enum.max(fn -> 0 end)

      max(header_width, max_cell)
    end)
  end

  defp cell_value(row, key) when is_map(row) do
    value =
      Map.get(row, key) ||
        atom_key_lookup(row, key)

    to_string(value || "")
  end

  defp atom_key_lookup(row, key) when is_binary(key) do
    try do
      Map.get(row, String.to_existing_atom(key))
    rescue
      ArgumentError -> nil
    end
  end

  defp atom_key_lookup(row, key) when is_atom(key) do
    Map.get(row, Atom.to_string(key))
  end

  defp atom_key_lookup(_row, _key), do: nil

  defp format_row_cells(columns, widths, value_fn) do
    columns
    |> Enum.zip(widths)
    |> Enum.map(fn {col, width} ->
      String.pad_trailing(value_fn.(col), width)
    end)
    |> Enum.join(" │ ")
  end

  defp separator_line(widths) do
    widths
    |> Enum.map(fn w -> String.duplicate("─", w) end)
    |> Enum.join("─┼─")
  end
end
