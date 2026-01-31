defmodule Alpa.Integration.StreamTest do
  @moduledoc """
  Integration tests for WebSocket streaming.

  Run with: mix test test/integration --include live

  Note: These tests verify connection establishment only.
  Full streaming tests require market hours and more complex setup.
  """
  use ExUnit.Case, async: false

  @moduletag :live

  alias Alpa.Stream.{TradeUpdates, MarketData}

  describe "TradeUpdates Stream" do
    test "start_link/1 connects to stream" do
      # Start the trade updates stream
      assert {:ok, pid} =
               TradeUpdates.start_link(
                 callback: fn event -> IO.inspect(event, label: "TradeUpdate") end
               )

      assert Process.alive?(pid)
      IO.puts("  TradeUpdates stream connected: #{inspect(pid)}")

      # Give it a moment to authenticate
      Process.sleep(2000)

      # Verify still alive after auth
      assert Process.alive?(pid)
      IO.puts("  Stream authenticated and running")

      # Stop the stream
      :ok = TradeUpdates.stop(pid)
      IO.puts("  Stream stopped")
    end
  end

  describe "MarketData Stream" do
    test "start_link/1 connects to IEX stream" do
      received = :ets.new(:test_events, [:set, :public])

      assert {:ok, pid} =
               MarketData.start_link(
                 callback: fn event ->
                   :ets.insert(received, {:event, event})
                 end,
                 feed: "iex"
               )

      assert Process.alive?(pid)
      IO.puts("  MarketData IEX stream connected: #{inspect(pid)}")

      # Give it a moment to authenticate
      Process.sleep(2000)

      assert Process.alive?(pid)
      IO.puts("  Stream authenticated")

      # Subscribe to a symbol
      :ok = MarketData.subscribe(pid, trades: ["AAPL"], quotes: ["AAPL"])
      IO.puts("  Subscribed to AAPL trades and quotes")

      # Wait for some data (may not receive any if market is closed)
      Process.sleep(3000)

      # Check if we received any events
      events = :ets.tab2list(received)
      IO.puts("  Events received: #{length(events)}")

      # Unsubscribe
      :ok = MarketData.unsubscribe(pid, trades: ["AAPL"], quotes: ["AAPL"])
      IO.puts("  Unsubscribed from AAPL")

      # Stop the stream
      :ok = MarketData.stop(pid)
      IO.puts("  Stream stopped")

      :ets.delete(received)
    end
  end
end
