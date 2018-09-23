defmodule Alchevents.Registry.TopicTest do
  use ExUnit.Case
  alias Alchevents.Registry.Topic

  setup do
    Registry.unregister_match(Alchevents.Registry.Topic, {:channel, :_}, [])
  end

  describe "#register" do
    test "register a new topic if no topic is registered for the same channel" do
      assert Registry.lookup(Alchevents.Registry.Topic, {:channel, :topic}) == []
      assert :ok == Topic.register(:channel, :topic)
      assert Registry.lookup(Alchevents.Registry.Topic, {:channel, :topic}) == [{self(), []}]
    end

    test "can't register the same topic twice for a channel" do
      assert Registry.lookup(Alchevents.Registry.Topic, {:channel, :topic}) == []
      assert :ok == Topic.register(:channel, :topic)
      assert {:error, {:already_registered, self()}} == Topic.register(:channel, :topic)
    end

    test "can register several topics for a channel" do
      assert Registry.lookup(Alchevents.Registry.Topic, {:channel, :topic}) == []
      assert :ok == Topic.register(:channel, :topic1)
      assert :ok == Topic.register(:channel, :topic2)
      assert :ok == Topic.register(:channel, :topic3)
    end
  end

  describe "#lookup" do
    test "returns not_found when the topic does not exist" do
      assert {:error, :not_found} == Topic.lookup(:channel, :topic)
    end

    test "returns ok and the pid of the topic when the topic is found" do
      assert :ok == Topic.register(:channel, :topic)
      assert {:ok, {self(), []}} == Topic.lookup(:channel, :topic)
    end
  end
end
