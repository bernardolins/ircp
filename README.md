# IRCP

[![Build Status](https://travis-ci.org/bernardolins/ircp.svg?branch=master)](https://travis-ci.org/bernardolins/ircp)

Create channels where you processes can talk to each other.

IRCP is powered by GenStage and Elixir's process Registry and allows you to create channels. Any process can publish a message to a channel, but only processes subscribed to a channel will receive then. Clients can also handle private messages and questions.

## Getting Started

A client can implement some callbacks who will be called when a it joins a channel, receive messages and questions.

```elixir
defmodule Counter do
  use IRCP.Client

  def set_info(options) do
    initial_value = Keyword.get(options, :initial_value, 0)
    {:ok, initial_value}
  end

  # This callback is called when a client joins a channel.
  def handle_join(_channel, initial_value) do
    {:ok, initial_value}
  end

  # When a someone publish a message to a channel, the other clients can handle that
  # message and do something to it. This callback does not send any reply to the sender.
  def handle_message({:increment, delta}, value) do
    {:noreply, value+delta}
  end

  # When someone sends a question to a client, the sender will wait for a reply.
  # Like GenServer's handle_cast, the second tuple element is the response
  # and the third is the client state.
  def handle_question(:current_value, _, value) do
    {:reply, value, value}
  end
end
```

## Sending messages to a client

```elixir
iex(1)> {:ok, client1} = Counter.create(initial_value: 0)
{:ok, #PID<0.188.0>}

iex(2)> IRCP.Channel.create(:values)
{:ok, #PID<0.190.0>}

iex(3)> IRCP.Client.join(client1, :values)
:ok

iex(4)> IRCP.Channel.publish(:values, {:increment, 1})
:ok

iex(5)> IRCP.Client.private_question(client1, :current_value)
1
```
