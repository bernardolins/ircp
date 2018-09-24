defmodule Alchevents.ListenerTest do
  use ExUnit.Case
  alias Alchevents.Listener
  alias Alchevents.Support.TestListener

  test "returns error and exit when topic does not exist" do
    Process.flag(:trap_exit, true)
    {:error, :topic_not_found} = TestListener.start_link(:channel, :topic)
    assert_receive {:EXIT, _, :topic_not_found}
  end

  test "init callback receives start_link options" do
    Alchevents.Topic.start_link(:channel, :topic)
    TestListener.start_link(:channel, :topic, [pid: self(), message: "hello"])
    assert_receive {:message, "hello"}
  end

  test "init callback returns the initial state of the listener" do
    Alchevents.Topic.start_link(:channel, :topic)
    {:ok, pid} = TestListener.start_link(:channel, :topic, [state: "initial_state"])
    assert Listener.query(pid, :return_state) == "initial_state"
  end

  test "publishing a message on a topic will call the corresponding handle_message callback" do
    Alchevents.Topic.start_link(:channel, :topic)
    TestListener.start_link(:channel, :topic)
    Alchevents.Topic.publish(:channel, :topic, {:send_to, self(), "hello"})
    assert_receive {:message, "hello"}
  end

  describe "#query" do
    test "query sends a message to the listener and wait the response if the query handler is implemented" do
      Alchevents.Topic.start_link(:channel, :topic)
      {:ok, pid} = TestListener.start_link(:channel, :topic, [pid: self(), message: "hello"])
      assert Listener.query(pid, {:return_message, "hello"}) == "hello"
    end
  end
end
