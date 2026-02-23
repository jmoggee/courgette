defmodule Courgette.Components.Tree do
  @moduledoc """
  Expandable/collapsible tree hierarchy display.

  Renders a nested data structure as an indented tree with keyboard
  navigation. Nodes with children can be expanded (arrow right) and
  collapsed (arrow left). Arrow up/down moves through visible nodes.
  Enter selects the current node.

  ## Props

  - `data` — tree data structure: list of nodes where each node is
    either a string (leaf) or `{label, children}` tuple (required)
  - `on_select` — message tag sent to parent when Enter is pressed (optional)
  - `expanded` — `MapSet` of node paths initially expanded (default all collapsed)

  ## Example

      live_component(Tree,
        id: "files",
        data: [
          {"src", ["main.ex", "helper.ex"]},
          {"test", ["main_test.ex"]},
          "README.md"
        ],
        on_select: :file_selected,
        focusable: true
      )
  """

  use Courgette.LiveComponent

  @impl true
  def mount(assigns) do
    expanded = assigns[:expanded] || MapSet.new()
    data = assigns[:data] || []
    flat_list = flatten(data, expanded)

    {:ok,
     assigns
     |> assign(:data, data)
     |> assign(:expanded, expanded)
     |> assign(:flat_list, flat_list)
     |> assign_new(:cursor, fn -> 0 end)
     |> assign_new(:on_select, fn -> nil end)
     |> assign_new(:focused, fn -> false end)}
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)

    new_assigns =
      if Map.has_key?(props, :data) or Map.has_key?(props, :expanded) do
        data = new_assigns.data
        expanded = new_assigns.expanded
        flat_list = flatten(data, expanded)

        new_assigns
        |> assign(:flat_list, flat_list)
        |> clamp_cursor()
      else
        new_assigns
      end

    {:ok, new_assigns}
  end

  @impl true
  def render(assigns) do
    border_color = if assigns.focused, do: :cyan, else: :white

    box border: :single, border_color: border_color do
      for {entry, idx} <- Enum.with_index(assigns.flat_list) do
        {label, depth, has_children?, expanded?, _path} = entry
        indent = String.duplicate(" ", depth * 2)

        prefix =
          cond do
            has_children? and expanded? -> "▾ "
            has_children? -> "▸ "
            true -> "• "
          end

        display = "#{indent}#{prefix}#{label}"
        selected? = idx == assigns.cursor and assigns.focused

        if selected? do
          text bold: true, fg: :cyan do
            display
          end
        else
          text do
            display
          end
        end
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
    max_idx = length(assigns.flat_list) - 1
    {:noreply, assign(assigns, :cursor, min(assigns.cursor + 1, max_idx))}
  end

  def handle_event({:key, :arrow_up}, assigns) do
    {:noreply, assign(assigns, :cursor, max(assigns.cursor - 1, 0))}
  end

  def handle_event({:key, :arrow_right}, assigns) do
    case Enum.at(assigns.flat_list, assigns.cursor) do
      {_label, _depth, true, false, path} ->
        expanded = MapSet.put(assigns.expanded, path)
        flat_list = flatten(assigns.data, expanded)

        {:noreply,
         assigns
         |> assign(:expanded, expanded)
         |> assign(:flat_list, flat_list)}

      _ ->
        {:noreply, assigns}
    end
  end

  def handle_event({:key, :arrow_left}, assigns) do
    case Enum.at(assigns.flat_list, assigns.cursor) do
      {_label, _depth, true, true, path} ->
        # Collapse this expanded node
        expanded = MapSet.delete(assigns.expanded, path)
        flat_list = flatten(assigns.data, expanded)

        assigns =
          assigns
          |> assign(:expanded, expanded)
          |> assign(:flat_list, flat_list)
          |> clamp_cursor()

        {:noreply, assigns}

      {_label, depth, _has_children?, _expanded?, path} when depth > 0 ->
        # Move to parent
        parent_path = Enum.take(path, length(path) - 1)

        parent_idx =
          Enum.find_index(assigns.flat_list, fn {_, _, _, _, p} -> p == parent_path end)

        if parent_idx do
          {:noreply, assign(assigns, :cursor, parent_idx)}
        else
          {:noreply, assigns}
        end

      _ ->
        {:noreply, assigns}
    end
  end

  def handle_event({:key, :enter}, assigns) do
    if assigns.on_select && assigns.parent_pid do
      case Enum.at(assigns.flat_list, assigns.cursor) do
        {label, _depth, _has_children?, _expanded?, _path} ->
          send(assigns.parent_pid, {assigns.on_select, label})

        _ ->
          :ok
      end
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # -- Flattening --

  @doc false
  @spec flatten(list(), MapSet.t()) :: list()
  def flatten(data, expanded) do
    flatten_nodes(data, expanded, 0, [])
  end

  defp flatten_nodes([], _expanded, _depth, acc), do: acc

  defp flatten_nodes([node | rest], expanded, depth, acc) do
    acc = flatten_node(node, expanded, depth, acc)
    flatten_nodes(rest, expanded, depth, acc)
  end

  defp flatten_node(label, _expanded, depth, acc) when is_binary(label) do
    path = compute_path(acc, depth)
    acc ++ [{label, depth, false, false, path}]
  end

  defp flatten_node({label, children}, expanded, depth, acc) do
    path = compute_path(acc, depth)
    is_expanded = MapSet.member?(expanded, path)
    entry = {label, depth, true, is_expanded, path}
    acc = acc ++ [entry]

    if is_expanded do
      flatten_nodes(children, expanded, depth + 1, acc)
    else
      acc
    end
  end

  defp compute_path(acc, depth) do
    # Count siblings at this depth to determine index
    # Path is the list of indices from root to this node
    parent_path =
      if depth == 0 do
        []
      else
        # Find the most recent entry at depth - 1 (our parent)
        acc
        |> Enum.reverse()
        |> Enum.find(fn {_, d, _, _, _} -> d == depth - 1 end)
        |> elem(4)
      end

    # Count how many siblings at this depth already exist under same parent
    sibling_count =
      acc
      |> Enum.count(fn {_, d, _, _, p} ->
        d == depth and Enum.take(p, length(parent_path)) == parent_path and
          length(p) == length(parent_path) + 1
      end)

    parent_path ++ [sibling_count]
  end

  defp clamp_cursor(assigns) do
    max_idx = max(length(assigns.flat_list) - 1, 0)
    assign(assigns, :cursor, min(assigns.cursor, max_idx))
  end
end
