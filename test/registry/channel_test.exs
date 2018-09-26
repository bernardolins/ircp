defmodule IRCP.Registry.ChannelTest do
  use ExUnit.Case
  alias IRCP.Registry.Channel

  setup do
    Registry.unregister_match(IRCP.Registry.Channel, :channel, [])
    Registry.unregister_match(IRCP.Registry.Channel, :channel1, [])
    Registry.unregister_match(IRCP.Registry.Channel, :channel2, [])
    Registry.unregister_match(IRCP.Registry.Channel, :channel3, [])
  end

  describe "#register" do
    test "register a new topic if no topic is registered for the same channel" do
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == []
      assert :ok == Channel.register(:channel)
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == [{self(), []}]
    end

    test "register a new topic and channel options if no topic is registered for the same channel" do
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == []
      assert :ok == Channel.register(:channel, [some: "option"])
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == [{self(), [some: "option"]}]
    end

    test "can't reg:channelister the same topic twice for a channel" do
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == []
      assert :ok == Channel.register(:channel)
      assert {:error, {:already_registered, self()}} == Channel.register(:channel)
    end

    test "can reg:channelister several topics for a channel" do
      assert Registry.lookup(IRCP.Registry.Channel, :channel) == []
      assert :ok == Channel.register(:channel1)
      assert :ok == Channel.register(:channel2)
      assert :ok == Channel.register(:channel3)
    end
  end

  describe "#lookup" do
    test "returns not_found when the topic does not exist" do
      assert {:error, :not_found} == Channel.lookup(:channel)
    end

    test "returns ok and the pid of the topic when the topic is found" do
      assert :ok == Channel.register(:channel)
      assert {:ok, {self(), []}} == Channel.lookup(:channel)
    end
  end
end
