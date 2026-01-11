defmodule Alpa.Integration.AlpaFacadeTest do
  @moduledoc """
  Integration tests for the main Alpa facade module.

  These tests verify the convenience functions exposed at the top level.

  Run with: mix test test/integration --include live
  """
  use ExUnit.Case, async: false

  @moduletag :live

  describe "Account functions" do
    test "account/0 returns account info" do
      assert {:ok, account} = Alpa.account()
      assert account.id != nil
      IO.puts("  Account: #{account.id}")
    end

    test "market_open?/0 returns boolean" do
      assert {:ok, is_open} = Alpa.market_open?()
      assert is_boolean(is_open)
      IO.puts("  Market open: #{is_open}")
    end
  end

  describe "Position functions" do
    test "positions/0 returns positions list" do
      assert {:ok, positions} = Alpa.positions()
      assert is_list(positions)
      IO.puts("  Positions: #{length(positions)}")
    end
  end

  describe "Order functions" do
    test "orders/0 returns orders list" do
      assert {:ok, orders} = Alpa.orders(status: "all", limit: 5)
      assert is_list(orders)
      IO.puts("  Orders: #{length(orders)}")
    end
  end

  describe "Market Data functions" do
    test "bars/2 returns bar data" do
      start_date = Date.utc_today() |> Date.add(-30)
      assert {:ok, bars} = Alpa.bars("AAPL", timeframe: "1Day", limit: 5, start: start_date)
      assert is_list(bars)
      IO.puts("  Bars: #{length(bars)}")
    end

    test "quotes/2 returns quote data" do
      assert {:ok, quotes} = Alpa.quotes("AAPL", limit: 5)
      assert is_list(quotes)
      IO.puts("  Quotes: #{length(quotes)}")
    end

    test "trades/2 returns trade data" do
      assert {:ok, trades} = Alpa.trades("AAPL", limit: 5)
      assert is_list(trades)
      IO.puts("  Trades: #{length(trades)}")
    end

    test "snapshot/1 returns market snapshot" do
      assert {:ok, snapshot} = Alpa.snapshot("AAPL")
      assert snapshot.symbol == "AAPL"
      IO.puts("  Snapshot: AAPL @ $#{snapshot.latest_trade.price}")
    end

    test "snapshots/1 returns multiple snapshots" do
      assert {:ok, snapshots} = Alpa.snapshots(["AAPL", "MSFT"])
      assert is_map(snapshots)
      assert map_size(snapshots) == 2
      IO.puts("  Snapshots: #{map_size(snapshots)} symbols")
    end

    test "latest_bar/1 returns latest bar" do
      assert {:ok, bar} = Alpa.latest_bar("AAPL")
      assert bar.symbol == "AAPL"
      IO.puts("  Latest bar: AAPL close $#{bar.close}")
    end

    test "latest_quote/1 returns latest quote" do
      assert {:ok, quote} = Alpa.latest_quote("AAPL")
      assert quote.symbol == "AAPL"
      IO.puts("  Latest quote: AAPL bid $#{quote.bid_price}")
    end

    test "latest_trade/1 returns latest trade" do
      assert {:ok, trade} = Alpa.latest_trade("AAPL")
      assert trade.symbol == "AAPL"
      IO.puts("  Latest trade: AAPL $#{trade.price}")
    end
  end

  describe "Asset functions" do
    test "assets/0 returns assets" do
      assert {:ok, assets} = Alpa.assets(status: "active", asset_class: "us_equity")
      assert is_list(assets)
      assert length(assets) > 0
      IO.puts("  Assets: #{length(assets)}")
    end

    test "asset/1 returns specific asset" do
      assert {:ok, asset} = Alpa.asset("AAPL")
      assert asset.symbol == "AAPL"
      IO.puts("  Asset: #{asset.symbol} - #{asset.name}")
    end
  end
end
