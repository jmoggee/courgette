defmodule Courgette.Components.LinkTest do
  use ExUnit.Case, async: true

  import Courgette.Components.Link

  describe "link/1" do
    test "renders label text" do
      el = link(label: "Click me")
      assert el.type == :text
      [content] = el.children
      assert content == "Click me"
    end

    test "has underline styling" do
      el = link(label: "Docs")
      assert el.props.underline == true
    end

    test "uses cyan color by default" do
      el = link(label: "Home")
      assert el.props.color == :cyan
    end

    test "custom color works" do
      el = link(label: "Link", color: :magenta)
      assert el.props.color == :magenta
    end

    test "url prop stored in props" do
      el = link(label: "Site", url: "https://example.com")
      assert el.props.url == "https://example.com"
    end

    test "url defaults to nil" do
      el = link(label: "No URL")
      assert el.props[:url] == nil
    end
  end
end
