defmodule Alchemessages.Channel.State do
  @moduledoc false

  defstruct [buffer: :queue.new, demand: 0, options: []]

  def new(opts \\ []), do: %__MODULE__{options: opts}

  def store_event(%__MODULE__{} = old_state, event) do
    new_event_store = :queue.in_r(event, old_state.buffer)
    %__MODULE__{old_state | buffer: new_event_store}
  end

  def next_event(%__MODULE__{} = old_state) do
    case :queue.out_r(old_state.buffer) do
      {{:value, event}, buffer} ->
        {:ok, event, %__MODULE__{old_state | buffer: buffer}}
      {:empty, buffer} ->
        {:empty, %__MODULE__{old_state | buffer: buffer}}
    end
  end

  def update_demand(%__MODULE__{} = old_state, demand_delta \\ 1) do
    new_demand = old_state.demand+demand_delta
    %__MODULE__{old_state | demand: new_demand}
  end
end
