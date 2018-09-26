defmodule Alchemessages.Channel.State do
  @moduledoc false

  defstruct [
    buffer: :queue.new,
    buffer_size: 0,
    demand: 0,
    options: []
  ]

  @default_max_buffer_size Application.get_env(:alchemessages, :max_buffer_size, 2_000)

  def new(opts \\ []) do
    %__MODULE__{options: opts}
  end

  def buffer_message(%__MODULE__{buffer_size: buffer_size, options: opts} = state, message) do
    max_buffer_size = Keyword.get(opts, :max_buffer_size, @default_max_buffer_size)

    if buffer_size < max_buffer_size do
      add_message_to_buffer(state, message)
    else
      state
    end
  end

  def next_message(%__MODULE__{buffer: buffer, buffer_size: buffer_size} = state) do
    case :queue.out_r(buffer) do
      {{:value, message}, buffer} ->
        {:ok, message, %__MODULE__{state | buffer: buffer, buffer_size: buffer_size-1}}
      {:empty, buffer} ->
        {:empty, %__MODULE__{state | buffer: buffer, buffer_size: buffer_size}}
    end
  end

  def update_demand(%__MODULE__{demand: demand} = state, demand_delta \\ 1) do
    demand = if demand+demand_delta > 0, do: demand+demand_delta, else: 0
    %__MODULE__{state | demand: demand}
  end

  defp add_message_to_buffer(%__MODULE__{buffer: buffer, buffer_size: buffer_size} = state, message) do
    %__MODULE__{state | buffer: :queue.in_r(message, buffer), buffer_size: buffer_size+1}
  end
end
