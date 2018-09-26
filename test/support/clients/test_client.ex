defmodule IRCP.Support.TestClient do
  use IRCP.Client

  def join(_, opts) do
    test_pid = Keyword.get(opts, :pid, nil)
    message = Keyword.get(opts, :message, "")
    state = Keyword.get(opts, :state, 0)
    if test_pid, do: send(test_pid, {:message, message})
    {:ok, state}
  end

  def handle_message({:send_to, pid, message}, state) do
    send(pid, {:message, message})
    {:noreply, state}
  end

  def handle_question({:return_message, message}, _from, state) do
    {:reply, message, state}
  end

  def handle_question(:return_state, _from, state) do
    {:reply, state, state}
  end
end
