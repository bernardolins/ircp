defmodule IRCP.ClientTest do
  use ExUnit.Case
  alias IRCP.Client
  alias IRCP.Support.TestClient

  test "returns error and exit when channel does not exist" do
    Process.flag(:trap_exit, true)
    {:error, :channel_not_found} = TestClient.start_link(:channel)
    assert_receive {:EXIT, _, :channel_not_found}
  end

  test "join callback receives start_link options" do
    IRCP.Channel.create(:channel)
    TestClient.start_link(:channel, [pid: self(), message: "hello"])
    assert_receive {:message, "hello"}
  end

  test "init callback returns the initial state of the client" do
    IRCP.Channel.create(:channel)
    {:ok, pid} = TestClient.start_link(:channel, [state: "initial_state"])
    assert Client.ask(pid, :return_state) == "initial_state"
  end

  test "publishing a message on a channel will call the corresponding handle_message callback" do
    IRCP.Channel.create(:channel)
    TestClient.start_link(:channel)
    IRCP.Channel.publish(:channel, {:send_to, self(), "hello"})
    assert_receive {:message, "hello"}
  end

  test "does nothing if an unknown message is published on the channel" do
    IRCP.Channel.create(:channel)
    {:ok, pid} = TestClient.start_link(:channel, state: 0)
    IRCP.Channel.publish(:channel, :unknown_message)
    assert Client.ask(pid, :return_state) == 0
  end

  test "send_after is handled by handle_message" do
    IRCP.Channel.create(:channel)
    {:ok, pid} = TestClient.start_link(:channel, state: 0)
    :timer.send_after(10, pid, {:send_to, self(), "hello"})
    assert_receive {:message, "hello"}
  end

  describe "#ask" do
    test "sends a message to the client and wait the response if the ask handler is implemented" do
      IRCP.Channel.create(:channel)
      {:ok, pid} = TestClient.start_link(:channel, [pid: self(), message: "hello"])
      assert Client.ask(pid, {:return_message, "hello"}) == "hello"
    end

    test "sends a message to the client and receives :not_implemented as response if the handler is not implemented" do
      IRCP.Channel.create(:channel)
      {:ok, pid} = TestClient.start_link(:channel, [pid: self(), message: "hello"])
      assert Client.ask(pid, :unknown_message) == :not_implemented
    end
  end

  describe "#tell" do
    test "sends an async message to the client" do
      IRCP.Channel.create(:channel)
      {:ok, pid} = TestClient.start_link(:channel)
      IRCP.Client.tell(pid, {:send_to, self(), "hello"})
      assert_receive {:message, "hello"}
    end
  end
end
