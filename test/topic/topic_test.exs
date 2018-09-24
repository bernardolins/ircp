defmodule Alchevents.TopicTest do
  use ExUnit.Case

  test "stop the topic if it is already registered" do
    Process.flag(:trap_exit, true)
    Alchevents.Topic.start_link(:channel, :topic)
    assert {:error, {:already_registered, _}} = Alchevents.Topic.start_link(:channel, :topic)
    assert_receive {:EXIT, _, {:already_registered, _}}
  end

  test "returns not_found if the topic is not registered" do
    Process.flag(:trap_exit, true)
    assert {:error, :topic_not_found} = Alchevents.Topic.publish(:channel, :topic, :some_message)
  end

  describe "#publish" do
    test "send event to a worker when it subscribe to the topic" do
      {:ok, pid} = Alchevents.Topic.start_link(:channel, :topic)
      Alchevents.Support.TestConsumer.start_link(pid, self())

      Alchevents.Topic.publish(:channel, :topic, :event1)
      :timer.sleep(100)

      assert_received{:received, [:event1]}
    end

    test "does nothing when no consumers are started" do
      {:ok, pid} = Alchevents.Topic.start_link(:channel, :topic)

      Alchevents.Topic.publish(:channel, :topic, :event1)
      :timer.sleep(100)

      refute_received{:received, [:event1]}
    end
  end
end
