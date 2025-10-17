#!/usr/bin/env elixir

# Simple test script to verify GraphQL subscriptions work
# Run with: elixir test_subscription.exs

Mix.install([
  {:websocket_client, "~> 1.3"}
])

defmodule SubscriptionTest do
  use WebSockex

  def start_link do
    WebSockex.start_link("ws://localhost:4000/socket/websocket", __MODULE__, %{})
  end

  def handle_connect(_conn, state) do
    IO.puts("Connected to WebSocket")

    # Send join message for Absinthe
    join_msg = %{
      topic: "__absinthe__:control",
      event: "phx_join",
      payload: %{},
      ref: "1"
    }

    {:reply, {:text, Jason.encode!(join_msg)}, state}
  end

  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"event" => "phx_reply", "payload" => %{"status" => "ok"}}} ->
        IO.puts("Joined successfully, now subscribing to stock updates...")

        # Subscribe to stock updates
        subscription_msg = %{
          topic: "__absinthe__:control",
          event: "doc",
          payload: %{
            query: "subscription { stockUpdated { id name sku stockCount } }"
          },
          ref: "2"
        }

        {:reply, {:text, Jason.encode!(subscription_msg)}, state}

      {:ok, %{"event" => "subscription:data", "payload" => %{"result" => %{"data" => data}}}} ->
        IO.puts("📦 STOCK UPDATE RECEIVED: #{inspect(data)}")
        {:ok, state}

      {:ok, other} ->
        IO.puts("Received: #{inspect(other)}")
        {:ok, state}
    end
  end

  def handle_disconnect(_connection, state) do
    IO.puts("Disconnected")
    {:ok, state}
  end
end

# Start the test
IO.puts("Testing GraphQL subscriptions...")
IO.puts("This will connect to the WebSocket and listen for stock updates.")
IO.puts("In another terminal, run: curl -X POST http://localhost:4000/api/simulate-stock-update")
IO.puts("You should see stock update notifications here.")
IO.puts("Press Ctrl+C to exit.")

{:ok, pid} = SubscriptionTest.start_link()

# Keep the script running
Process.sleep(:infinity)
