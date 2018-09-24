defmodule Alchemessages.ListenerTest do
  use ExUnit.Case
  alias Alchemessages.Listener
  alias Alchemessages.Support.TestListener

  test "returns error and exit when channel does not exist" do
    Process.flag(:trap_exit, true)
    {:error, :channel_not_found} = TestListener.start_link(:channel)
    assert_receive {:EXIT, _, :channel_not_found}
  end

  test "join callback receives start_link options" do
    Alchemessages.Channel.start_link(:channel)
    TestListener.start_link(:channel, [pid: self(), message: "hello"])
    assert_receive {:message, "hello"}
  end

  test "init callback returns the initial state of the listener" do
    Alchemessages.Channel.start_link(:channel)
    {:ok, pid} = TestListener.start_link(:channel, [state: "initial_state"])
    assert Listener.ask(pid, :return_state) == "initial_state"
  end

  test "publishing a message on a channel will call the corresponding handle_message callback" do
    Alchemessages.Channel.start_link(:channel)
    TestListener.start_link(:channel)
    Alchemessages.Channel.publish(:channel, {:send_to, self(), "hello"})
    assert_receive {:message, "hello"}
  end

  test "does nothing if an unknown message is published on the channel" do
    Alchemessages.Channel.start_link(:channel)
    {:ok, pid} = TestListener.start_link(:channel, state: 0)
    Alchemessages.Channel.publish(:channel, :unknown_message)
    assert Listener.ask(pid, :return_state) == 0
  end

  describe "#ask" do
    test "sends a message to the listener and wait the response if the ask handler is implemented" do
      Alchemessages.Channel.start_link(:channel)
      {:ok, pid} = TestListener.start_link(:channel, [pid: self(), message: "hello"])
      assert Listener.ask(pid, {:return_message, "hello"}) == "hello"
    end

    test "sends a message to the listener and receives :not_implemented as response if the handler is not implemented" do
      Alchemessages.Channel.start_link(:channel)
      {:ok, pid} = TestListener.start_link(:channel, [pid: self(), message: "hello"])
      assert Listener.ask(pid, :unknown_message) == :not_implemented
    end
  end

  describe "#tell" do
    test "sends an async message to the listener" do
      Alchemessages.Channel.start_link(:channel)
      {:ok, pid} = TestListener.start_link(:channel)
      Alchemessages.Listener.tell(pid, {:send_to, self(), "hello"})
      assert_receive {:message, "hello"}
    end
  end
end
