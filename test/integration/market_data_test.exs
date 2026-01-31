defmodule Alpa.Integration.MarketDataTest do
  @moduledoc """
  Integration tests for Market Data API endpoints.

  Run with: mix test test/integration --include live
  """
  use ExUnit.Case, async: false

  @moduletag :live

  alias Alpa.MarketData.{Bars, Quotes, Trades, Snapshots}

  # ============================================================================
  # Bars
  # ============================================================================

  describe "Bars" do
    test "get/2 returns historical bars" do
      # Use a date range to ensure we get data
      start_date = Date.utc_today() |> Date.add(-30)
      assert {:ok, bars} = Bars.get("AAPL", timeframe: "1Day", limit: 5, start: start_date)
      assert is_list(bars)

      if length(bars) > 0 do
        [bar | _] = bars
        assert bar.open != nil
        assert bar.high != nil
        assert bar.low != nil
        assert bar.close != nil
        assert bar.volume != nil

        IO.puts("  AAPL bars retrieved: #{length(bars)}")

        IO.puts(
          "  Latest: O:#{bar.open} H:#{bar.high} L:#{bar.low} C:#{bar.close} V:#{bar.volume}"
        )
      else
        IO.puts("  AAPL bars: 0 (check date range)")
      end
    end

    test "get_multi/2 returns bars for multiple symbols" do
      assert {:ok, bars_map} =
               Bars.get_multi(["AAPL", "MSFT", "GOOGL"], timeframe: "1Day", limit: 3)

      assert is_map(bars_map)

      IO.puts("  Multi-symbol bars:")

      Enum.each(bars_map, fn {symbol, bars} ->
        IO.puts("    #{symbol}: #{length(bars)} bars")
      end)
    end

    test "get_latest/1 returns latest bar" do
      assert {:ok, bar} = Bars.latest("AAPL")
      assert bar.symbol == "AAPL"
      assert bar.close != nil
      IO.puts("  AAPL latest bar close: $#{bar.close}")
    end

    test "get_latest_multi/1 returns latest bars for multiple symbols" do
      assert {:ok, bars_map} = Bars.latest_multi(["AAPL", "MSFT"])
      assert is_map(bars_map)
      assert Map.has_key?(bars_map, "AAPL")
      IO.puts("  Latest bars for #{map_size(bars_map)} symbols")
    end
  end

  # ============================================================================
  # Quotes
  # ============================================================================

  describe "Quotes" do
    test "get/2 returns historical quotes" do
      assert {:ok, quotes} = Quotes.get("AAPL", limit: 5)
      assert is_list(quotes)

      if length(quotes) > 0 do
        [quote | _] = quotes
        assert quote.bid_price != nil
        assert quote.ask_price != nil
        IO.puts("  AAPL quotes retrieved: #{length(quotes)}")
        IO.puts("  Latest: Bid:$#{quote.bid_price} Ask:$#{quote.ask_price}")
      else
        IO.puts("  AAPL quotes: 0 (market may be closed)")
      end
    end

    test "get_latest/1 returns latest quote" do
      assert {:ok, quote} = Quotes.latest("AAPL")
      assert quote.symbol == "AAPL"
      IO.puts("  AAPL latest quote: Bid:$#{quote.bid_price} Ask:$#{quote.ask_price}")
    end

    test "get_latest_multi/1 returns latest quotes for multiple symbols" do
      assert {:ok, quotes_map} = Quotes.latest_multi(["AAPL", "MSFT", "GOOGL"])
      assert is_map(quotes_map)
      IO.puts("  Latest quotes for #{map_size(quotes_map)} symbols")
    end
  end

  # ============================================================================
  # Trades
  # ============================================================================

  describe "Trades" do
    test "get/2 returns historical trades" do
      assert {:ok, trades} = Trades.get("AAPL", limit: 5)
      assert is_list(trades)

      if length(trades) > 0 do
        [trade | _] = trades
        assert trade.price != nil
        assert trade.size != nil
        IO.puts("  AAPL trades retrieved: #{length(trades)}")
        IO.puts("  Latest: $#{trade.price} x #{trade.size}")
      else
        IO.puts("  AAPL trades: 0 (market may be closed)")
      end
    end

    test "get_latest/1 returns latest trade" do
      assert {:ok, trade} = Trades.latest("AAPL")
      assert trade.symbol == "AAPL"
      IO.puts("  AAPL latest trade: $#{trade.price} x #{trade.size}")
    end

    test "get_latest_multi/1 returns latest trades for multiple symbols" do
      assert {:ok, trades_map} = Trades.latest_multi(["AAPL", "MSFT"])
      assert is_map(trades_map)
      IO.puts("  Latest trades for #{map_size(trades_map)} symbols")
    end
  end

  # ============================================================================
  # Snapshots
  # ============================================================================

  describe "Snapshots" do
    test "get/1 returns market snapshot" do
      assert {:ok, snapshot} = Snapshots.get("AAPL")
      assert snapshot.symbol == "AAPL"
      assert snapshot.latest_trade != nil
      assert snapshot.latest_quote != nil

      IO.puts("  AAPL Snapshot:")
      IO.puts("    Latest Trade: $#{snapshot.latest_trade.price}")

      IO.puts(
        "    Latest Quote: Bid:$#{snapshot.latest_quote.bid_price} Ask:$#{snapshot.latest_quote.ask_price}"
      )

      if snapshot.minute_bar do
        IO.puts("    Minute Bar Close: $#{snapshot.minute_bar.close}")
      end

      if snapshot.daily_bar do
        IO.puts("    Daily Bar Close: $#{snapshot.daily_bar.close}")
      end
    end

    test "get_multi/1 returns snapshots for multiple symbols" do
      assert {:ok, snapshots_map} = Snapshots.get_multi(["AAPL", "MSFT", "GOOGL"])
      assert is_map(snapshots_map)
      assert map_size(snapshots_map) == 3

      IO.puts("  Snapshots retrieved: #{map_size(snapshots_map)}")

      Enum.each(snapshots_map, fn {symbol, snapshot} ->
        # Handle both parsed structs and raw maps
        price =
          case snapshot do
            %{latest_trade: %{price: p}} -> p
            %{"latestTrade" => %{"p" => p}} -> p
            _ -> "N/A"
          end

        IO.puts("    #{symbol}: $#{price}")
      end)
    end
  end
end
