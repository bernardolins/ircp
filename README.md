# IRCP

IRCP comes from "IRC for Proccess" and is like IRC, but for proccess!

IRCP is powered by GenStage and Elixir's process Registry and allows you to create channels where a client (process) can join to send and receive messages from other clients on the same channel. Clients can also send private synchronous or asynchronous messages to each other.

## Getting Started

Define a client module:

```elixir
defmodule HelloClient do
  use IRCP.Client

  # This callback is called when a client joins a channel.
  def join(channel, _) do
    Alchemessages.Channel.publish(channel, {:joined, self()})

    {:ok, :whatever}
  end

  # When a client publish a message to a channel, the other clients can handle that
  # message and do something to it. This callback does not send any reply to the sender.
  def handle_message({:joined, who}, value) do
    if who != self() do
      IO.puts "Welcome #{inspect who}, I am #{inspect self()}"
    end

    {:noreply, :whatever}
  end

  # When someone sends a question to a client, the proccess must reply it.
  # Like GenServer's handle_cast, the second tuple element is the response
  # and the third is the client state.
  def handle_question(:whoami, _, _) do
    {:reply, self(), :whatever}
  end
end
```

Create a channel and let then talk:

```elixir
iex(1)> IRCP.Channel.create("#hello")
{:ok, #PID<0.179.0>}
iex(2)> HelloClient.start_link("#hello")
{:ok, #PID<0.181.0>}
iex(3)> HelloClient.start_link("#hello")
Welcome #PID<0.183.0>, I am #PID<0.181.0>
{:ok, #PID<0.183.0>}
iex(4)> HelloClient.start_link("#hello")
Welcome #PID<0.185.0>, I am #PID<0.183.0>
Welcome #PID<0.185.0>, I am #PID<0.181.0>
{:ok, #PID<0.185.0>}
```
