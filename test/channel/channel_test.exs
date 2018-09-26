defmodule Alchemessages.ChannelTest do
  use ExUnit.Case

  test "stop the topic if it is already registered" do
    Process.flag(:trap_exit, true)
    Alchemessages.Channel.start_link(:channel)
    assert {:error, {:already_registered, _}} = Alchemessages.Channel.start_link(:channel)
    assert_receive {:EXIT, _, {:already_registered, _}}
  end

  test "returns not_found if the topic is not registered" do
    Process.flag(:trap_exit, true)
    assert {:error, :topic_not_found} = Alchemessages.Channel.publish(:channel, :some_message)
  end

  describe "#publish" do
    test "send event to a worker when it subscribe to the topic" do
      {:ok, pid} = Alchemessages.Channel.start_link(:channel)
      Alchemessages.Support.TestConsumer.start_link(pid, self())
      Alchemessages.Channel.publish(:channel, :event1)
      :timer.sleep(100)
      assert_received{:received, [:event1]}
    end

    test "does nothing when no consumers are started" do
      Alchemessages.Channel.start_link(:channel)
      Alchemessages.Channel.publish(:channel, :event1)
      :timer.sleep(100)
      refute_received{:received, [:event1]}
    end
  end
end