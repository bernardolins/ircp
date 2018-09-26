defmodule IRCP.ChannelTest do
  use ExUnit.Case

  test "stop the topic if it is already registered" do
    Process.flag(:trap_exit, true)
    IRCP.Channel.create(:channel)
    assert {:error, {:already_registered, _}} = IRCP.Channel.create(:channel)
    assert_receive {:EXIT, _, {:already_registered, _}}
  end

  test "returns not_found if the topic is not registered" do
    Process.flag(:trap_exit, true)
    assert {:error, :topic_not_found} = IRCP.Channel.publish(:channel, :some_message)
  end

  describe "#publish" do
    test "send message to a worker when it subscribe to the topic" do
      {:ok, pid} = IRCP.Channel.create(:channel)
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish(:channel, :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end

    test "does nothing when no consumers are started" do
      IRCP.Channel.create(:channel)
      IRCP.Channel.publish(:channel, :message1)
      :timer.sleep(100)
      refute_received{:received, [:message1]}
    end
  end
end
