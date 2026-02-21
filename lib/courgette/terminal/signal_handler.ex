defmodule Courgette.Terminal.SignalHandler do
  @moduledoc false

  # A gen_event handler registered on erl_signal_server.
  # Forwards :sigwinch events to the Terminal GenServer.

  @behaviour :gen_event

  @impl true
  def init(terminal_pid) do
    {:ok, terminal_pid}
  end

  @impl true
  def handle_event(:sigwinch, terminal_pid) do
    send(terminal_pid, :sigwinch)
    {:ok, terminal_pid}
  end

  def handle_event(_event, terminal_pid) do
    {:ok, terminal_pid}
  end

  @impl true
  def handle_call(_request, terminal_pid) do
    {:ok, :ok, terminal_pid}
  end

  @impl true
  def handle_info(_info, terminal_pid) do
    {:ok, terminal_pid}
  end

  @impl true
  def terminate(_reason, _terminal_pid) do
    :ok
  end
end
