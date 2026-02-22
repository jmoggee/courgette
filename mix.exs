defmodule Courgette.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/loam/courgette"

  def project do
    [
      app: :courgette,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Courgette",
      description: "A declarative TUI framework for Elixir, built on OTP",
      source_url: @source_url,
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "guides/architecture.md",
        "guides/css-flexbox-compliance.md",
        "guides/cheatsheets/dsl.cheatmd",
        "guides/cheatsheets/events.cheatmd",
        "AGENTS.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_extras: [
        Guides: ["guides/architecture.md", "guides/css-flexbox-compliance.md", "AGENTS.md"],
        Cheatsheets: ["guides/cheatsheets/dsl.cheatmd", "guides/cheatsheets/events.cheatmd"]
      ],
      groups_for_modules: [
        "Core": [
          Courgette,
          Courgette.App,
          Courgette.Element,
          Courgette.Theme
        ],
        "Components": [
          Courgette.Component,
          Courgette.Component.DSL,
          Courgette.LiveComponent,
          Courgette.Components,
          Courgette.Components.TextInput,
          Courgette.Components.Textarea,
          Courgette.Components.Select,
          Courgette.Components.Spinner,
          Courgette.Components.ProgressBar
        ],
        "Layout": [
          Courgette.Layout.Engine,
          Courgette.Layout.Engine.Flex,
          Courgette.Layout.Engine.Style,
          Courgette.Layout.Engine.Geometry,
          Courgette.Layout.Engine.Text,
          Courgette.Layout.Engine.Round,
          Courgette.Layout.Bounds
        ],
        "Rendering": [
          Courgette.Renderer,
          Courgette.Painter,
          Courgette.Buffer,
          Courgette.Buffer.Cell,
          Courgette.Buffer.Diff,
          Courgette.Buffer.Writer,
          Courgette.Buffer.DoubleBuffer,
          Courgette.ANSI,
          Courgette.ANSI.ColorMode
        ],
        "Terminal & Input": [
          Courgette.Terminal,
          Courgette.Terminal.KeyParser,
          Courgette.Terminal.SignalHandler,
          Courgette.FocusManager
        ],
        "Animation": [
          Courgette.Animation.Easing,
          Courgette.Animation.Frames,
          Courgette.Animation.Tween
        ],
        "Testing": [
          Courgette.ComponentTestHelpers
        ],
        "Internal": [
          Courgette.ComponentRegistry,
          Courgette.LiveComponent.Server,
          Courgette.LiveComponent.Lifecycle
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://github.com/loam/rhyzo-architecture/blob/main/spec/appendices/C-courgette-framework.md"
      }
    ]
  end
end
