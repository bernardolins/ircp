defmodule Alchemessages.Channel.StateTest do
  use ExUnit.Case
  alias Alchemessages.Channel.State

  describe "#new" do
    test "creates a struct with an empty queue and demand 0" do
      assert %{data: {[], []}, demand: 0} = State.new
    end
  end

  describe "#store_event" do
    test "adds a new event on state" do
      state = State.new
      assert :queue.is_empty(state.data)
      state = State.store_event(state, :event1)
      assert :queue.len(state.data) == 1
    end
  end

  describe "#next_event" do
    test "returns empty and the state if there are no events" do
      state = State.new
      assert {:empty, _} = State.next_event(state)
    end

    test "removes the oldest event from the state" do
      state =
        State.new
        |> State.store_event(:event1)
        |> State.store_event(:event2)

      assert {:ok, :event1, state} = State.next_event(state)
      assert {:ok, :event2, state} = State.next_event(state)
    end
  end

  describe "#update_demand" do
    test "increments demand by delta when delta is provided" do
      state = State.new
      assert state.demand == 0
      state = State.update_demand(state, 8)
      assert state.demand == 8
    end

    test "increments demand by 1 when no delta is provided" do
      state = State.new
      assert state.demand == 0
      state = State.update_demand(state)
      assert state.demand == 1
    end
  end
end
