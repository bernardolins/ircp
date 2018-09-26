defmodule Alchemessages.Channel.StateTest do
  use ExUnit.Case
  alias Alchemessages.Channel.State

  describe "#new" do
    test "creates a struct with an empty queue and demand 0" do
      assert %{buffer: {[], []}, demand: 0} = State.new
   end

    test "accepts and option list and store it on structure" do
      assert %{options: [some: "option"]} = State.new([some: "option"])
   end
  end

  describe "#store_event" do
    test "adds a new event on state if buffer is not full" do
      state = State.new
      assert :queue.is_empty(state.buffer)
      assert state.buffer_size == 0
      state = State.store_event(state, :event1)
      assert :queue.len(state.buffer) == 1
      assert state.buffer_size == 1
    end

    test "doest not store message on state if buffer is full" do
      state = State.new([max_buffer_size: 1])
      assert :queue.is_empty(state.buffer)
      assert state.buffer_size == 0
      state = State.store_event(state, :event1)
      assert :queue.len(state.buffer) == 1
      state = State.store_event(state, :event1)
      assert :queue.len(state.buffer) == 1
      assert state.buffer_size == 1
    end
  end

  describe "#next_event" do
    test "returns empty and the state if there are no events" do
      state = State.new
      assert {:empty, _} = State.next_event(state)
      assert state.buffer_size == 0
    end

    test "removes the oldest event from the state" do
      state =
        State.new
        |> State.store_event(:event1)
        |> State.store_event(:event2)

      assert state.buffer_size == 2

      assert {:ok, :event1, state} = State.next_event(state)
      assert state.buffer_size == 1
      assert {:ok, :event2, state} = State.next_event(state)
      assert state.buffer_size == 0
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

    test "accepts negative demand" do
      state = State.new
      state = State.update_demand(state, 10)
      assert state.demand == 10
      state = State.update_demand(state, -1)
      assert state.demand == 9
    end

    test "does not decrement demand bellow 0" do
      state = State.new
      assert state.demand == 0
      state = State.update_demand(state, -1)
      assert state.demand == 0
    end
  end
end
