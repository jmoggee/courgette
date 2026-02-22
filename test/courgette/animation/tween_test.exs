defmodule Courgette.Animation.TweenTest do
  use ExUnit.Case, async: true

  alias Courgette.Animation.Tween

  # --- Helper: injectable Agent-backed clock ---

  defp agent_clock(initial \\ 0) do
    {:ok, agent} = Agent.start_link(fn -> initial end)
    clock = fn -> Agent.get(agent, & &1) end
    advance = fn ms -> Agent.update(agent, &(&1 + ms)) end
    {clock, advance}
  end

  # --- new/3 ---

  test "new creates tween with defaults" do
    {clock, _} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    assert tween.from == 0
    assert tween.to == 100
    assert tween.duration == 1000
    assert tween.easing == :linear
    assert tween.started_at == nil
  end

  test "new accepts easing option" do
    {clock, _} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, easing: :ease_in, clock: clock)
    assert tween.easing == :ease_in
  end

  test "new requires duration" do
    assert_raise KeyError, fn ->
      Tween.new(0, 100, [])
    end
  end

  # --- step/1 ---

  test "step lazy-starts on first call" do
    {clock, _} = agent_clock(1000)
    tween = Tween.new(0, 100, duration: 500, clock: clock)
    assert tween.started_at == nil

    {:running, _value, tween} = Tween.step(tween)
    assert tween.started_at == 1000
  end

  test "step returns from value at t=0" do
    {clock, _} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, value, _tween} = Tween.step(tween)
    assert value == 0.0
  end

  test "step interpolates linearly at midpoint" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(500)
    {:running, value, _tween} = Tween.step(tween)
    assert_in_delta value, 50.0, 0.01
  end

  test "step returns :done when duration elapsed" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(1000)
    assert {:done, 100} = Tween.step(tween)
  end

  test "step returns :done when past duration" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(2000)
    assert {:done, 100} = Tween.step(tween)
  end

  test "step applies easing function" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, easing: :ease_in, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(500)
    {:running, value, _tween} = Tween.step(tween)
    # ease_in at 0.5 → 0.25, so value should be 25
    assert_in_delta value, 25.0, 0.01
  end

  test "step with custom easing function" do
    cube = fn t -> t * t * t end
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, easing: cube, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(500)
    {:running, value, _tween} = Tween.step(tween)
    # t=0.5, cube=0.125, value=12.5
    assert_in_delta value, 12.5, 0.01
  end

  test "step works with negative ranges" do
    {clock, advance} = agent_clock()
    tween = Tween.new(100, 0, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(500)
    {:running, value, _tween} = Tween.step(tween)
    assert_in_delta value, 50.0, 0.01
  end

  test "step works with float values" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0.0, 1.0, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(250)
    {:running, value, _tween} = Tween.step(tween)
    assert_in_delta value, 0.25, 0.001
  end

  # --- value/1 ---

  test "value returns from before start" do
    {clock, _} = agent_clock()
    tween = Tween.new(50, 200, duration: 1000, clock: clock)
    assert Tween.value(tween) == 50
  end

  test "value returns interpolated after step" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(500)
    assert_in_delta Tween.value(tween), 50.0, 0.01
  end

  test "value returns to when past duration" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(2000)
    assert Tween.value(tween) == 100
  end

  # --- reset/1 ---

  test "reset clears started_at" do
    {clock, _} = agent_clock()
    tween = Tween.new(0, 100, duration: 1000, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    assert tween.started_at != nil

    tween = Tween.reset(tween)
    assert tween.started_at == nil
  end

  test "reset allows re-running the tween" do
    {clock, advance} = agent_clock()
    tween = Tween.new(0, 100, duration: 100, clock: clock)
    {:running, _value, tween} = Tween.step(tween)
    advance.(100)
    assert {:done, 100} = Tween.step(tween)

    tween = Tween.reset(tween)
    # Step again — should start fresh from current clock time
    {:running, value, _tween} = Tween.step(tween)
    assert value == 0.0
  end

  # --- Timer helpers ---

  test "start_timer schedules :tween_tick" do
    assigns = %{foo: :bar}
    assigns = Tween.start_timer(assigns)
    assert is_reference(assigns.__tween_timer__)
    assert_receive :tween_tick, 100
  end

  test "stop_timer cancels the timer" do
    assigns = Tween.start_timer(%{})
    assigns = Tween.stop_timer(assigns)
    refute Map.has_key?(assigns, :__tween_timer__)
    refute_receive :tween_tick, 50
  end

  test "stop_timer is safe when no timer exists" do
    assigns = Tween.stop_timer(%{})
    refute Map.has_key?(assigns, :__tween_timer__)
  end

  test "named start_timer sends {name}_tick" do
    assigns = Tween.start_timer(%{}, :opacity)
    assert is_reference(assigns.__opacity_timer__)
    assert_receive :opacity_tick, 100
  end

  test "named stop_timer cancels named timer" do
    assigns = Tween.start_timer(%{}, :opacity)
    assigns = Tween.stop_timer(assigns, :opacity)
    refute Map.has_key?(assigns, :__opacity_timer__)
    refute_receive :opacity_tick, 50
  end

  test "multiple named timers are independent" do
    assigns =
      %{}
      |> Tween.start_timer(:opacity)
      |> Tween.start_timer(:position)

    assert is_reference(assigns.__opacity_timer__)
    assert is_reference(assigns.__position_timer__)

    assigns = Tween.stop_timer(assigns, :opacity)
    refute Map.has_key?(assigns, :__opacity_timer__)
    assert is_reference(assigns.__position_timer__)

    assert_receive :position_tick, 100
    refute_receive :opacity_tick, 50
  end

  test "start_timer preserves existing assigns" do
    assigns = %{count: 42, label: "test"}
    assigns = Tween.start_timer(assigns)
    assert assigns.count == 42
    assert assigns.label == "test"
    assert_receive :tween_tick, 100
  end
end
