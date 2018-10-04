defmodule IRCP.ChannelTest do
  use ExUnit.Case
  alias IRCP.Support.ValidationClient

  describe "#create" do
    test "stop the channel creation if it is already registered" do
      Process.flag(:trap_exit, true)
      IRCP.Channel.create(:channel)
      assert {:error, {:already_registered, _}} = IRCP.Channel.create(:channel)
      assert_receive {:EXIT, _, {:already_registered, _}}
    end

    test "accepts atom channel names" do
      assert {:ok, _} = IRCP.Channel.create(:channel)
    end

    test "accepts string channel names" do
      assert {:ok, _} = IRCP.Channel.create("channel")
    end

    test "accepts list channel names" do
      assert {:ok, _} = IRCP.Channel.create([:channel, :for, :users])
    end

    test "accepts KeywordList channel names" do
      assert {:ok, _} = IRCP.Channel.create(channel_name: "my_channel")
    end

    test "accepts integer channel names" do
      assert {:ok, _} = IRCP.Channel.create(1)
    end
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

    test "returns not_found if the channel is not registered" do
      Process.flag(:trap_exit, true)
      assert {:error, :channel_not_found} = IRCP.Channel.publish(:channel, :some_message)
    end

    test "accepts publish messagens when the channel name is an atom" do
      {:ok, pid} = IRCP.Channel.create(:channel)
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish(:channel, :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end

    test "accepts publish messagens when the channel name is a string" do
      {:ok, pid} = IRCP.Channel.create("channel")
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish("channel", :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end

    test "accepts publish messagens when the channel name is a list" do
      {:ok, pid} = IRCP.Channel.create([:channel, :for, :users])
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish([:channel, :for, :users], :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end

    test "accepts publish messagens when the channel name is a KeywordList" do
      {:ok, pid} = IRCP.Channel.create(channel_name: "my_channel")
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish([channel_name: "my_channel"], :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end

    test "accepts publish messagens when the channel name is a number" do
      {:ok, pid} = IRCP.Channel.create(1)
      IRCP.Support.TestConsumer.start_link(pid, self())
      IRCP.Channel.publish(1, :message1)
      :timer.sleep(100)
      assert_received{:received, [:message1]}
    end
  end

  describe "#join" do
    test "allows a client to join a channel" do
      IRCP.Channel.create(:channel)
      {:ok, pid} = ValidationClient.create(pid: self())
      assert :ok = IRCP.Channel.join(:channel, pid)
      IRCP.Channel.publish(:channel, :test_callback)
      assert_receive {:handle_message_called, _}
    end

    test "returns error when a client tries do join a channel that does not exist" do
      {:ok, pid} = ValidationClient.create(pid: self())
      assert {:error, :not_found} == IRCP.Channel.join(:channel, pid)
    end
  end
end
