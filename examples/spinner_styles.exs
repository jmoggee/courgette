# examples/spinner_styles.exs
#
# Displays all 30 spinner styles simultaneously, organized by family.
# Each spinner runs independently in its own process.
#
# Press 'q' to quit.
#
# Run: mix run examples/spinner_styles.exs

:logger.set_primary_config(:level, :none)

Courgette.ComponentRegistry.create_table()

alias Courgette.Components.Spinner

defmodule SpinnerStylesDemo do
  use Courgette.App

  @braille [
    {:dots, "dots", "classic rotation"},
    {:dots_pulse, "dots_pulse", "fills then empties"},
    {:dots_orbit, "dots_orbit", "single dot tracing"},
    {:dots_scroll, "dots_scroll", "dense, one gap sweeps"},
    {:dots_bounce, "dots_bounce", "swells and recedes"},
    {:sand, "sand", "hourglass fill/empty"},
    {:braille_double, "braille_double", "two dots orbiting"},
    {:braille_six, "braille_six", "inverse, one missing sweeps"},
    {:braille_eight_double, "braille_eight_double", "two gaps sweeping"}
  ]

  @geometric [
    {:circle, "circle", "half-circle rotation"},
    {:arc, "arc", "smooth arc sweep"},
    {:triangle, "triangle", "rotating corner"},
    {:quarter, "quarter", "quarter-circle rotation"},
    {:box_bounce, "box_bounce", "quadrant bounce"},
    {:pipe, "pipe", "box-drawing corners"},
    {:box_invert, "box_invert", "three quadrants filled"},
    {:square_corners, "square_corners", "quarter-filled squares"}
  ]

  @block [
    {:wave, "wave", "vertical block pulse"},
    {:pulse, "pulse", "density fade"},
    {:meter, "meter", "bar fill/empty"},
    {:grow_horizontal, "grow_horizontal", "horizontal grow/shrink"},
    {:noise, "noise", "static/interference"},
    {:layer, "layer", "accumulating lines"}
  ]

  @classic [
    {:line, "line", "ASCII rotation"},
    {:star, "star", "twinkling"},
    {:point, "point", "traveling dot"},
    {:bounce, "bounce", "single dot orbit"},
    {:arrow, "arrow", "compass directions"},
    {:ellipsis, "ellipsis", "thinking indicator"},
    {:hamburger, "hamburger", "trigram lines"}
  ]

  @impl true
  def mount(_assigns) do
    {:ok, %{}}
  end

  @impl true
  def render(assigns) do
    box flex_direction: :column do
      text bold: true, fg: :yellow do
        "Spinner Styles"
      end

      text fg: :white, dim: true do
        "30 styles, 4 families. q to quit."
      end

      box padding_v: 1 do
        render_family(assigns, "Braille", :cyan, @braille)
      end

      box padding_v: 1 do
        render_family(assigns, "Geometric", :magenta, @geometric)
      end

      box padding_v: 1 do
        render_family(assigns, "Block", :green, @block)
      end

      box padding_v: 1 do
        render_family(assigns, "Classic", :yellow, @classic)
      end
    end
  end

  defp render_family(_assigns, label, color, styles) do
    box flex_direction: :column do
      text bold: true, fg: color do
        label
      end

      for {style, name, desc} <- styles do
        box flex_direction: :row do
          live_component(Spinner,
            id: "spin-#{name}",
            style: style,
            color: color
          )

          text fg: :white do
            "  #{name}"
          end

          text fg: :white, dim: true do
            "  #{desc}"
          end
        end
      end
    end
  end

  @impl true
  def handle_event({:key, {:char, "q"}}, _assigns) do
    Courgette.stop(self())
    {:noreply, %{}}
  end

  def handle_event(_event, assigns) do
    {:noreply, assigns}
  end

  @impl true
  def handle_info(_msg, assigns) do
    {:noreply, assigns}
  end
end

Courgette.run(SpinnerStylesDemo)
