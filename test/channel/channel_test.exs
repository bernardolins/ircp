defmodule Alchevents.ChannelTest do
  use ExUnit.Case

  test "stop the topic if it is already registered" do
    Process.flag(:trap_exit, true)
    Alchevents.Channel.start_link(:channel)
    assert {:error, {:already_registered, _}} = Alchevents.Channel.start_link(:channel)
    assert_receive {:EXIT, _, {:already_registered, _}}
  end

  test "returns not_found if the topic is not registered" do
    Process.flag(:trap_exit, true)
    assert {:error, :topic_not_found} = Alchevents.Channel.publish(:channel, :some_message)
  end

  describe "#publish" do
    test "send event to a worker when it subscribe to the topic" do
      {:ok, pid} = Alchevents.Channel.start_link(:channel)
      Alchevents.Support.TestConsumer.start_link(pid, self())

      Alchevents.Channel.publish(:channel, :event1)
      :timer.sleep(100)

      assert_received{:received, [:event1]}
    end

    test "does nothing when no consumers are started" do
      {:ok, pid} = Alchevents.Channel.start_link(:channel)

      Alchevents.Channel.publish(:channel, :event1)
      :timer.sleep(100)

      refute_received{:received, [:event1]}
    end
  end
end
