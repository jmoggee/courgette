# examples/task_tracker.exs
#
# Task Tracker — a demo app exercising every Courgette component.
#
# Three screens: Dashboard (list + sidebar), Detail/Edit, New Task.
# All data is stubbed in-memory. Fully keyboard-driven.
#
# Components used: Select, TextInput, Textarea, Spinner, ProgressBar,
# badge, divider, heading, key_value, empty_state, ScrollArea,
# Tween + Easing, Focus management, Theme tokens.
#
# Run: mix run examples/task_tracker.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Animation.Tween
alias Courgette.Components.{ProgressBar, Spinner, Select, TextInput, Textarea}

# ────────────────────────────────────────────────────────────────
# TaskListComponent — focusable LiveComponent for the task list
# ────────────────────────────────────────────────────────────────

defmodule TaskTracker.TaskListComponent do
  use Courgette.LiveComponent
  import Courgette.Components

  @impl true
  def mount(assigns) do
    {:ok, %{
      tasks: assigns[:tasks] || [],
      on_select: assigns[:on_select] || :task_selected,
      cursor: 0,
      focused: false,
      parent_pid: assigns[:parent_pid]
    }}
  end

  @impl true
  def update(props, assigns) do
    new_assigns = Map.merge(assigns, props)
    # Clamp cursor to new task list length
    max_idx = max(length(Map.get(new_assigns, :tasks, [])) - 1, 0)
    cursor = min(Map.get(new_assigns, :cursor, 0), max_idx)
    {:ok, Map.put(new_assigns, :cursor, cursor)}
  end

  @impl true
  def render(assigns) do
    tasks = assigns.tasks
    cursor = assigns.cursor
    focused = assigns.focused

    border_color = if focused, do: :cyan, else: :white

    box flex_direction: :column, border: :rounded, border_color: border_color, flex: 1 do
      if Enum.empty?(tasks) do
        empty_state(message: "No tasks match filter")
      else
        for {task, idx} <- Enum.with_index(tasks) do
          render_task_row(task, idx, cursor, focused)
        end
      end
    end
  end

  defp render_task_row(task, idx, cursor, focused) do
    is_selected = idx == cursor
    indicator = if is_selected, do: "▸ ", else: "  "
    text_color = if is_selected and focused, do: :cyan, else: :white

    # Priority color
    priority_color = case task.priority do
      :critical -> :red
      :high -> :yellow
      :medium -> :blue
      :low -> :bright_black
    end

    # Status indicator
    status_icon = case task.status do
      :done -> "✓"
      :in_review -> "◎"
      :in_progress -> "●"
      :todo -> "○"
    end

    # Text-based progress bar (avoids spawning ProgressBar processes)
    filled = round(task.progress * 10)
    empty = 10 - filled
    progress_bar = String.duplicate("█", filled) <> String.duplicate("░", empty)
    pct = round(task.progress * 100)

    title_style = [{:color, text_color} | if(is_selected, do: [{:bold, true}], else: [{:dim, true}])]
    progress_style = [{:color, :green} | if(is_selected, do: [], else: [{:dim, true}])]

    box flex_direction: :column do
      box flex_direction: :row do
        text title_style do
          "#{indicator}#{status_icon} ##{task.id} #{task.title}"
        end
      end

      box flex_direction: :row do
        text dim: true do
          "    "
        end

        badge(label: hd(task.tags), color: :cyan)

        text color: priority_color, bold: true do
          " #{task.priority |> Atom.to_string() |> String.upcase()}"
        end

        text progress_style do
          "  #{progress_bar} #{pct}%"
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

  def handle_event({:key, :arrow_up}, assigns) do
    new_cursor = max(assigns.cursor - 1, 0)
    {:noreply, assign(assigns, :cursor, new_cursor)}
  end

  def handle_event({:key, :arrow_down}, assigns) do
    max_idx = max(length(assigns.tasks) - 1, 0)
    new_cursor = min(assigns.cursor + 1, max_idx)
    {:noreply, assign(assigns, :cursor, new_cursor)}
  end

  def handle_event({:key, :enter}, assigns) do
    task = Enum.at(assigns.tasks, assigns.cursor)

    if task && assigns.parent_pid do
      send(assigns.parent_pid, {assigns.on_select, task})
    end

    {:noreply, assigns}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end
end

# ────────────────────────────────────────────────────────────────
# TaskTracker — root App
# ────────────────────────────────────────────────────────────────

defmodule TaskTracker do
  use Courgette.App
  import Courgette.Components

  @statuses [:all, :todo, :in_progress, :in_review, :done]
  @sorts [:id, :priority, :progress]
  @priority_order %{critical: 0, high: 1, medium: 2, low: 3}

  @initial_tasks [
    %{
      id: 1,
      title: "Implement user authentication",
      description: "Add login/logout flow with session management.\nSupport email + password and OAuth providers.",
      status: :in_progress,
      priority: :high,
      tags: ["feature", "security"],
      progress: 0.65,
      assignee: "Alice",
      created: "2026-02-10"
    },
    %{
      id: 2,
      title: "Fix pagination bug",
      description: "Page 2+ returns empty results when filter is active.\nRoot cause: offset not applied after WHERE clause.",
      status: :in_review,
      priority: :critical,
      tags: ["bug"],
      progress: 0.90,
      assignee: "Bob",
      created: "2026-02-12"
    },
    %{
      id: 3,
      title: "Write API documentation",
      description: "Document all REST endpoints with examples.\nUse OpenAPI 3.0 spec format.",
      status: :todo,
      priority: :medium,
      tags: ["docs"],
      progress: 0.0,
      assignee: "Carol",
      created: "2026-02-14"
    },
    %{
      id: 4,
      title: "Add dark mode support",
      description: "Implement theme switching with system preference detection.\nPersist user choice in local storage.",
      status: :in_progress,
      priority: :medium,
      tags: ["feature", "ui"],
      progress: 0.40,
      assignee: "Alice",
      created: "2026-02-15"
    },
    %{
      id: 5,
      title: "Optimize database queries",
      description: "Profile slow queries on the dashboard.\nAdd missing indexes and batch N+1 loads.",
      status: :todo,
      priority: :high,
      tags: ["performance"],
      progress: 0.0,
      assignee: "Dave",
      created: "2026-02-16"
    },
    %{
      id: 6,
      title: "Set up CI pipeline",
      description: "Configure GitHub Actions for tests, lint, and deploy.\nAdd status badges to README.",
      status: :done,
      priority: :low,
      tags: ["devops"],
      progress: 1.0,
      assignee: "Eve",
      created: "2026-02-08"
    }
  ]

  # ── Mount ──────────────────────────────────────────────────

  @impl true
  def mount(_assigns) do
    {:ok, %{
      current_view: :dashboard,
      tasks: @initial_tasks,
      next_id: 7,

      # Dashboard state
      filter_index: 0,
      sort_index: 0,

      # Detail view state
      selected_task: nil,
      detail_progress: 0.0,
      tween: nil,

      # New task form state
      form_title: "",
      form_description: "",
      form_priority: nil,
      form_status: nil
    }}
  end

  # ── Render dispatch ────────────────────────────────────────

  @impl true
  def render(assigns) do
    case assigns.current_view do
      :dashboard -> render_dashboard(assigns)
      :detail -> render_detail(assigns)
      :new_task -> render_new_task(assigns)
    end
  end

  # ── Dashboard ──────────────────────────────────────────────

  defp render_dashboard(assigns) do
    tasks = filtered_tasks(assigns)
    filter_label = @statuses |> Enum.at(assigns.filter_index) |> format_status()
    sort_label = @sorts |> Enum.at(assigns.sort_index) |> Atom.to_string() |> String.capitalize()

    total = length(assigns.tasks)
    done = Enum.count(assigns.tasks, & &1.status == :done)
    active = Enum.count(assigns.tasks, & &1.status in [:in_progress, :in_review])
    avg_progress = if total > 0, do: Enum.sum(Enum.map(assigns.tasks, & &1.progress)) / total, else: 0.0

    box flex_direction: :column do
      # Title bar
      box flex_direction: :column, padding_h: 1 do
        heading(text: "Task Tracker", color: :cyan)

        text color: :bright_black do
          "Tab: focus | ↑↓: select | Enter: open | n: new | f: filter | s: sort | q: quit"
        end
      end

      # Main content: list + sidebar
      box flex_direction: :row, flex: 1 do
        # Task list (left, flex)
        box flex_direction: :column, flex: 2 do
          live_component(TaskTracker.TaskListComponent,
            id: "task_list",
            focusable: true,
            tasks: tasks,
            on_select: :task_selected
          )
        end

        # Sidebar (right, fixed-ish)
        box flex_direction: :column, flex: 1, border: :rounded, border_color: :bright_black, padding_h: 1 do
          # Stats
          heading(text: "Stats", color: :yellow, divider: false)
          key_value(label: "Total", value: "#{total}")
          key_value(label: "Done", value: "#{done}")
          key_value(label: "Active", value: "#{active}")

          divider([])

          # Overall progress
          heading(text: "Progress", color: :yellow, divider: false)

          live_component(ProgressBar,
            id: "overall_progress",
            value: avg_progress,
            width: 20,
            color: :green,
            label: :percent
          )

          divider([])

          # Syncing spinner
          live_component(Spinner,
            id: "sync_spinner",
            style: :dots,
            label: "Syncing...",
            color: :cyan
          )

          divider([])

          # Filter display
          heading(text: "Filter", color: :yellow, divider: false)
          key_value(label: "Status", value: filter_label)
          key_value(label: "Sort", value: sort_label)

          live_component(Select,
            id: "filter_select",
            focusable: true,
            options: Enum.map(@statuses, fn s -> {Atom.to_string(s), format_status(s)} end),
            selected: assigns.filter_index,
            on_select: :filter_changed,
            prompt: "Filter by:"
          )
        end
      end
    end
  end

  # ── Detail View ────────────────────────────────────────────

  defp render_detail(assigns) do
    task = assigns.selected_task

    # Priority badge color
    priority_color = case task.priority do
      :critical -> :red
      :high -> :yellow
      :medium -> :blue
      :low -> :bright_black
    end

    # Status badge color
    status_color = case task.status do
      :done -> :green
      :in_review -> :cyan
      :in_progress -> :yellow
      :todo -> :bright_black
    end

    box flex_direction: :column do
      # Title bar
      box flex_direction: :column, padding_h: 1 do
        heading(text: "Task ##{task.id}: #{task.title}", color: :cyan)

        text color: :bright_black do
          "Esc: back | Tab: cycle fields"
        end
      end

      # Metadata row
      box flex_direction: :row, padding_h: 1 do
        badge(label: task.status |> Atom.to_string() |> String.replace("_", " "), color: status_color)
        badge(label: task.priority |> Atom.to_string(), color: priority_color)

        for tag <- task.tags do
          badge(label: tag, color: :cyan)
        end
      end

      box flex_direction: :row, padding_h: 1 do
        key_value(label: "Assignee", value: task.assignee)

        text dim: true do
          "  "
        end

        key_value(label: "Created", value: task.created)
      end

      divider([])

      # Animated progress bar
      box padding_h: 1 do
        heading(text: "Progress", color: :yellow, divider: false)

        live_component(ProgressBar,
          id: "detail_progress",
          value: assigns.detail_progress,
          width: 30,
          color: :green,
          label: :percent
        )
      end

      divider([])

      # Editable fields
      box flex_direction: :column, padding_h: 1, flex: 1 do
        text color: :bright_black, bold: true do
          "Title:"
        end

        live_component(TextInput,
          id: "detail_title",
          focusable: true,
          value: task.title,
          on_change: :detail_title_changed,
          on_submit: :detail_title_submitted
        )

        text color: :bright_black, bold: true do
          "Description:"
        end

        live_component(Textarea,
          id: "detail_description",
          focusable: true,
          value: task.description,
          on_change: :detail_desc_changed,
          height: 6
        )

        box flex_direction: :row do
          box flex_direction: :column, flex: 1 do
            text color: :bright_black, bold: true do
              "Status:"
            end

            live_component(Select,
              id: "detail_status",
              focusable: true,
              options: [
                {"todo", "To Do"},
                {"in_progress", "In Progress"},
                {"in_review", "In Review"},
                {"done", "Done"}
              ],
              selected: status_to_index(task.status),
              on_select: :detail_status_changed
            )
          end

          box flex_direction: :column, flex: 1 do
            text color: :bright_black, bold: true do
              "Priority:"
            end

            live_component(Select,
              id: "detail_priority",
              focusable: true,
              options: [
                {"low", "Low"},
                {"medium", "Medium"},
                {"high", "High"},
                {"critical", "Critical"}
              ],
              selected: priority_to_index(task.priority),
              on_select: :detail_priority_changed
            )
          end
        end
      end
    end
  end

  # ── New Task Form ──────────────────────────────────────────

  defp render_new_task(assigns) do
    form_pristine = assigns.form_title == "" and assigns.form_description == ""

    box flex_direction: :column do
      # Title bar
      box flex_direction: :column, padding_h: 1 do
        heading(text: "New Task", color: :cyan)

        text color: :bright_black do
          "Esc: cancel | Tab: next field | Enter (in title): create"
        end
      end

      divider([])

      # Form fields
      box flex_direction: :column, padding_h: 1, flex: 1 do
        text color: :bright_black, bold: true do
          "Title:"
        end

        live_component(TextInput,
          id: "new_title",
          focusable: true,
          placeholder: "Enter task title...",
          on_change: :new_title_changed,
          on_submit: :new_task_submit
        )

        text color: :bright_black, bold: true do
          "Description:"
        end

        live_component(Textarea,
          id: "new_description",
          focusable: true,
          placeholder: "Enter task description...",
          on_change: :new_desc_changed,
          height: 5
        )

        box flex_direction: :row do
          box flex_direction: :column, flex: 1 do
            text color: :bright_black, bold: true do
              "Priority:"
            end

            live_component(Select,
              id: "new_priority",
              focusable: true,
              options: [
                {"low", "Low"},
                {"medium", "Medium"},
                {"high", "High"},
                {"critical", "Critical"}
              ],
              on_select: :new_priority_changed
            )
          end

          box flex_direction: :column, flex: 1 do
            text color: :bright_black, bold: true do
              "Status:"
            end

            live_component(Select,
              id: "new_status",
              focusable: true,
              options: [
                {"todo", "To Do"},
                {"in_progress", "In Progress"},
                {"in_review", "In Review"},
                {"done", "Done"}
              ],
              on_select: :new_status_changed
            )
          end
        end

        divider([])

        # Status indicator
        if form_pristine do
          empty_state(message: "Fill in the form above to create a new task")
        else
          box flex_direction: :row do
            live_component(Spinner,
              id: "form_spinner",
              style: :star,
              color: :green
            )

            text color: :green, bold: true do
              " Ready to create — press Enter in title field"
            end
          end
        end
      end
    end
  end

  # ── Event Handlers ─────────────────────────────────────────

  @impl true
  def handle_event({:key, {:char, "q"}}, assigns) do
    if assigns.current_view == :dashboard do
      Courgette.stop()
      {:noreply, assigns}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, :escape}, assigns) do
    case assigns.current_view do
      :detail ->
        assigns = cancel_tween(assigns)
        {:noreply, assign(assigns, :current_view, :dashboard)}

      :new_task ->
        {:noreply, assign(assigns,
          current_view: :dashboard,
          form_title: "",
          form_description: "",
          form_priority: nil,
          form_status: nil
        )}

      _ ->
        {:noreply, assigns}
    end
  end

  def handle_event({:key, {:char, "n"}}, assigns) do
    if assigns.current_view == :dashboard do
      {:noreply, assign(assigns,
        current_view: :new_task,
        form_title: "",
        form_description: "",
        form_priority: nil,
        form_status: nil
      )}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, {:char, "f"}}, assigns) do
    if assigns.current_view == :dashboard do
      new_index = rem(assigns.filter_index + 1, length(@statuses))
      {:noreply, assign(assigns, :filter_index, new_index)}
    else
      {:noreply, assigns}
    end
  end

  def handle_event({:key, {:char, "s"}}, assigns) do
    if assigns.current_view == :dashboard do
      new_index = rem(assigns.sort_index + 1, length(@sorts))
      {:noreply, assign(assigns, :sort_index, new_index)}
    else
      {:noreply, assigns}
    end
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  # ── Info Handlers ──────────────────────────────────────────

  @impl true
  def handle_info({:task_selected, task}, assigns) do
    # Navigate to detail view with tween animation
    tween = if Courgette.animations_enabled?() do
      Tween.new(0.0, task.progress, duration: 800, easing: :ease_out_cubic)
    end

    assigns = assign(assigns,
      current_view: :detail,
      selected_task: task,
      detail_progress: 0.0,
      tween: tween
    )

    assigns = if tween, do: Tween.start_timer(assigns, :detail_progress), else: assign(assigns, :detail_progress, task.progress)

    {:noreply, assigns}
  end

  # Tween tick for detail progress animation
  def handle_info(:detail_progress_tick, assigns) do
    if assigns.tween do
      case Tween.step(assigns.tween) do
        {:running, value, tween} ->
          assigns = assign(assigns, tween: tween, detail_progress: value)
          assigns = Tween.start_timer(assigns, :detail_progress)
          {:noreply, assigns}

        {:done, value} ->
          assigns = Tween.stop_timer(assigns, :detail_progress)
          assigns = assign(assigns, detail_progress: value, tween: nil)
          {:noreply, assigns}
      end
    else
      {:noreply, assigns}
    end
  end

  # Filter changed via Select
  def handle_info({:filter_changed, value}, assigns) do
    index = Enum.find_index(@statuses, fn s -> Atom.to_string(s) == value end) || 0
    {:noreply, assign(assigns, :filter_index, index)}
  end

  # Detail view — field changes
  def handle_info({:detail_title_changed, title}, assigns) do
    task = %{assigns.selected_task | title: title}
    tasks = update_task_in_list(assigns.tasks, task)
    {:noreply, assign(assigns, selected_task: task, tasks: tasks)}
  end

  def handle_info({:detail_title_submitted, _title}, assigns) do
    {:noreply, assigns}
  end

  def handle_info({:detail_desc_changed, desc}, assigns) do
    task = %{assigns.selected_task | description: desc}
    tasks = update_task_in_list(assigns.tasks, task)
    {:noreply, assign(assigns, selected_task: task, tasks: tasks)}
  end

  def handle_info({:detail_status_changed, value}, assigns) do
    status = String.to_existing_atom(value)
    task = %{assigns.selected_task | status: status}
    tasks = update_task_in_list(assigns.tasks, task)
    {:noreply, assign(assigns, selected_task: task, tasks: tasks)}
  end

  def handle_info({:detail_priority_changed, value}, assigns) do
    priority = String.to_existing_atom(value)
    task = %{assigns.selected_task | priority: priority}
    tasks = update_task_in_list(assigns.tasks, task)
    {:noreply, assign(assigns, selected_task: task, tasks: tasks)}
  end

  # New task form — field changes
  def handle_info({:new_title_changed, title}, assigns) do
    {:noreply, assign(assigns, :form_title, title)}
  end

  def handle_info({:new_desc_changed, desc}, assigns) do
    {:noreply, assign(assigns, :form_description, desc)}
  end

  def handle_info({:new_priority_changed, value}, assigns) do
    {:noreply, assign(assigns, :form_priority, String.to_existing_atom(value))}
  end

  def handle_info({:new_status_changed, value}, assigns) do
    {:noreply, assign(assigns, :form_status, String.to_existing_atom(value))}
  end

  # New task submit
  def handle_info({:new_task_submit, title}, assigns) do
    if String.trim(title) != "" do
      new_task = %{
        id: assigns.next_id,
        title: String.trim(title),
        description: assigns.form_description,
        status: assigns.form_status || :todo,
        priority: assigns.form_priority || :medium,
        tags: ["new"],
        progress: 0.0,
        assignee: "Unassigned",
        created: "2026-02-22"
      }

      {:noreply, assign(assigns,
        tasks: assigns.tasks ++ [new_task],
        next_id: assigns.next_id + 1,
        current_view: :dashboard,
        form_title: "",
        form_description: "",
        form_priority: nil,
        form_status: nil
      )}
    else
      {:noreply, assigns}
    end
  end

  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end

  # ── Helpers ────────────────────────────────────────────────

  defp filtered_tasks(assigns) do
    status_filter = Enum.at(@statuses, assigns.filter_index)
    sort_key = Enum.at(@sorts, assigns.sort_index)

    assigns.tasks
    |> then(fn tasks ->
      if status_filter == :all, do: tasks, else: Enum.filter(tasks, & &1.status == status_filter)
    end)
    |> sort_tasks(sort_key)
  end

  defp sort_tasks(tasks, :id), do: Enum.sort_by(tasks, & &1.id)
  defp sort_tasks(tasks, :priority), do: Enum.sort_by(tasks, & @priority_order[&1.priority])
  defp sort_tasks(tasks, :progress), do: Enum.sort_by(tasks, & &1.progress, :desc)

  defp format_status(:all), do: "All"
  defp format_status(:todo), do: "To Do"
  defp format_status(:in_progress), do: "In Progress"
  defp format_status(:in_review), do: "In Review"
  defp format_status(:done), do: "Done"

  defp status_to_index(:todo), do: 0
  defp status_to_index(:in_progress), do: 1
  defp status_to_index(:in_review), do: 2
  defp status_to_index(:done), do: 3

  defp priority_to_index(:low), do: 0
  defp priority_to_index(:medium), do: 1
  defp priority_to_index(:high), do: 2
  defp priority_to_index(:critical), do: 3

  defp update_task_in_list(tasks, updated_task) do
    Enum.map(tasks, fn task ->
      if task.id == updated_task.id, do: updated_task, else: task
    end)
  end

  defp cancel_tween(assigns) do
    if assigns.tween do
      assigns
      |> Tween.stop_timer(:detail_progress)
      |> assign(:tween, nil)
    else
      assigns
    end
  end
end

# ── Entry point ──────────────────────────────────────────────

Courgette.run(TaskTracker)
