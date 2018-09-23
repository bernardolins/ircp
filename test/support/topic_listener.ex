defmodule Alchevents.Support.TopicListener do
  def start_link(producer_pid, test_pid) do
    GenStage.start_link(__MODULE__, {producer_pid, test_pid})
  end

  def init({producer_pid, test_pid}) do
    {:consumer, test_pid, subscribe_to: [producer_pid]}
  end

  def handle_events(events, _from, test_pid) do
    send(test_pid, {:received, events})
    {:noreply, [], test_pid}
  end
end
