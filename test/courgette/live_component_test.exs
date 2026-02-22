defmodule Courgette.LiveComponentTest do
  use ExUnit.Case

  alias Courgette.LiveComponent

  # -- Test module that uses the behaviour --

  defmodule TestComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(assigns) do
      {:ok, assign(assigns, :mounted, true)}
    end

    @impl true
    def render(assigns) do
      text do
        "count: #{assigns[:count] || 0}"
      end
    end

    @impl true
    def handle_event({:key, :arrow_up}, assigns) do
      {:noreply, update(assigns, :count, &(&1 + 1))}
    end

    def handle_event(_event, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def handle_info(:ping, assigns) do
      {:noreply, assign(assigns, :pinged, true)}
    end

    def handle_info(_msg, assigns) do
      {:noreply, assigns}
    end

    @impl true
    def terminate(_reason, _assigns) do
      :ok
    end
  end

  # Module with only required callbacks
  defmodule MinimalComponent do
    use Courgette.LiveComponent

    @impl true
    def mount(_assigns), do: {:ok, %{}}

    @impl true
    def render(_assigns) do
      box do
        text(do: "minimal")
      end
    end
  end

  describe "behaviour compilation" do
    test "module with all callbacks compiles" do
      assert function_exported?(TestComponent, :mount, 1)
      assert function_exported?(TestComponent, :render, 1)
      assert function_exported?(TestComponent, :handle_event, 2)
      assert function_exported?(TestComponent, :handle_info, 2)
      assert function_exported?(TestComponent, :terminate, 2)
    end

    test "module with only required callbacks compiles" do
      assert function_exported?(MinimalComponent, :mount, 1)
      assert function_exported?(MinimalComponent, :render, 1)
      refute function_exported?(MinimalComponent, :handle_event, 2)
      refute function_exported?(MinimalComponent, :handle_info, 2)
    end

    test "DSL macros are available" do
      # Verify render returns an Element
      tree = TestComponent.render(%{count: 5})
      assert %Courgette.Element{type: :text} = tree
    end
  end

  describe "assign/2 with map" do
    test "merges map into assigns" do
      assigns = %{a: 1}
      result = LiveComponent.assign(assigns, %{b: 2, c: 3})
      assert result == %{a: 1, b: 2, c: 3}
    end

    test "overwrites existing keys" do
      assigns = %{a: 1, b: 2}
      result = LiveComponent.assign(assigns, %{b: 99})
      assert result == %{a: 1, b: 99}
    end

    test "accepts keyword list" do
      assigns = %{a: 1}
      result = LiveComponent.assign(assigns, b: 2, c: 3)
      assert result == %{a: 1, b: 2, c: 3}
    end
  end

  describe "assign/3" do
    test "sets a single key" do
      assigns = %{a: 1}
      result = LiveComponent.assign(assigns, :b, 2)
      assert result == %{a: 1, b: 2}
    end

    test "overwrites existing key" do
      assigns = %{a: 1}
      result = LiveComponent.assign(assigns, :a, 99)
      assert result == %{a: 99}
    end
  end

  describe "assign_new/3" do
    test "sets key when absent" do
      assigns = %{a: 1}
      result = LiveComponent.assign_new(assigns, :b, fn -> 42 end)
      assert result == %{a: 1, b: 42}
    end

    test "does not overwrite existing key" do
      assigns = %{a: 1}
      result = LiveComponent.assign_new(assigns, :a, fn -> 99 end)
      assert result == %{a: 1}
    end

    test "function is not called when key exists" do
      assigns = %{a: 1}
      # If called, this would raise
      result = LiveComponent.assign_new(assigns, :a, fn -> raise "should not be called" end)
      assert result == %{a: 1}
    end
  end

  describe "update/3" do
    test "applies function to existing key" do
      assigns = %{count: 5}
      result = LiveComponent.update(assigns, :count, &(&1 + 1))
      assert result == %{count: 6}
    end

    test "raises when key is missing" do
      assigns = %{a: 1}

      assert_raise KeyError, fn ->
        LiveComponent.update(assigns, :missing, &(&1 + 1))
      end
    end
  end
end
