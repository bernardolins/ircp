defmodule Alchevents.ListenerTest do
  use ExUnit.Case
  alias Alchevents.Listener
  alias Alchevents.Support.TestListener

  test "returns error and exit when channel does not exist" do
    Process.flag(:trap_exit, true)
    {:error, :channel_not_found} = TestListener.start_link(:channel)
    assert_receive {:EXIT, _, :channel_not_found}
  end

  test "init callback receives start_link options" do
    Alchevents.Channel.start_link(:channel)
    TestListener.start_link(:channel, [pid: self(), message: "hello"])
    assert_receive {:message, "hello"}
  end

  test "init callback returns the initial state of the listener" do
    Alchevents.Channel.start_link(:channel)
    {:ok, pid} = TestListener.start_link(:channel, [state: "initial_state"])
    assert Listener.query(pid, :return_state) == "initial_state"
  end

  test "publishing a message on a channel will call the corresponding handle_message callback" do
    Alchevents.Channel.start_link(:channel)
    TestListener.start_link(:channel)
    Alchevents.Channel.publish(:channel, {:send_to, self(), "hello"})
    assert_receive {:message, "hello"}
  end

  describe "#query" do
    test "query sends a message to the listener and wait the response if the query handler is implemented" do
      Alchevents.Channel.start_link(:channel)
      {:ok, pid} = TestListener.start_link(:channel, [pid: self(), message: "hello"])
      assert Listener.query(pid, {:return_message, "hello"}) == "hello"
    end
  end
end
