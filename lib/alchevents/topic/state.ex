defmodule Alchevents.Topic.State do
  @moduledoc false

  defstruct [data: :queue.new, demand: 0]

  def new(), do: %__MODULE__{}

  def store_event(%__MODULE__{} = old_state, event) do
    new_event_store = :queue.in_r(event, old_state.data)
    %__MODULE__{old_state | data: new_event_store}
  end

  def next_event(%__MODULE__{} = old_state) do
    case :queue.out_r(old_state.data) do
      {{:value, event}, data} ->
        {:ok, event, %__MODULE__{old_state | data: data}}
      {:empty, data} ->
        {:empty, %__MODULE__{old_state | data: data}}
    end
  end

  def update_demand(%__MODULE__{} = old_state, demand_delta \\ 1) do
    new_demand = old_state.demand+demand_delta
    %__MODULE__{old_state | demand: new_demand}
  end
end
