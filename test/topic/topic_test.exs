defmodule Alchevents.TopicTest do
  use ExUnit.Case

  describe "#publish" do
    test "send event to a worker when it subscribe to the topic" do
      {:ok, pid} = Alchevents.Topic.start_link(:channel, :topic)
      Alchevents.Support.TestConsumer.start_link(pid, self())

      Alchevents.Topic.publish(:channel, :topic, :event1)
      :timer.sleep(100)

      assert_received{:received, [:event1]}
    end
  end
end
