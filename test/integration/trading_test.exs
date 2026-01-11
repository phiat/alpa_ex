defmodule Alpa.Integration.TradingTest do
  @moduledoc """
  Integration tests for Trading API endpoints.

  Run with: mix test test/integration --include live

  Requires APCA_API_KEY_ID and APCA_API_SECRET_KEY environment variables.
  Tests run against paper trading API.
  """
  use ExUnit.Case, async: false

  @moduletag :live

  alias Alpa.Trading.{Account, Orders, Positions, Assets, Watchlists, Market}

  # ============================================================================
  # Account
  # ============================================================================

  describe "Account" do
    test "get/0 returns account info" do
      assert {:ok, account} = Account.get()
      assert account.id != nil
      assert account.status != nil
      assert account.buying_power != nil
      assert account.cash != nil
      assert account.portfolio_value != nil
      IO.puts("  Account ID: #{account.id}")
      IO.puts("  Status: #{account.status}")
      IO.puts("  Buying Power: $#{account.buying_power}")
    end

    test "get_configurations/0 returns account config" do
      assert {:ok, config} = Account.get_configurations()
      assert is_map(config)
      assert is_boolean(config["no_shorting"]) or is_nil(config["no_shorting"])
      IO.puts("  DTBP Check: #{config["dtbp_check"]}")
      IO.puts("  Trade Confirm Email: #{config["trade_confirm_email"]}")
    end

    test "get_activities/0 returns activities list" do
      assert {:ok, activities} = Account.get_activities()
      assert is_list(activities)
      IO.puts("  Activities count: #{length(activities)}")
    end

    test "get_portfolio_history/0 returns history" do
      assert {:ok, history} = Account.get_portfolio_history(period: "1W", timeframe: "1D")
      assert is_map(history)
      assert is_list(history["timestamp"]) or is_nil(history["timestamp"])
      IO.puts("  History points: #{length(history["timestamp"] || [])}")
    end
  end

  # ============================================================================
  # Market
  # ============================================================================

  describe "Market" do
    test "clock/0 returns market clock" do
      assert {:ok, clock} = Market.get_clock()
      assert is_boolean(clock.is_open)
      IO.puts("  Market Open: #{clock.is_open}")
      IO.puts("  Next Open: #{clock.next_open}")
      IO.puts("  Next Close: #{clock.next_close}")
    end

    test "calendar/0 returns trading calendar" do
      assert {:ok, calendar} = Market.get_calendar()
      assert is_list(calendar)
      assert length(calendar) > 0
      [first | _] = calendar
      # Handle both parsed structs and raw maps
      date = Map.get(first, :date) || Map.get(first, "date")
      assert date != nil
      IO.puts("  Calendar days: #{length(calendar)}")
    end
  end

  # ============================================================================
  # Assets
  # ============================================================================

  describe "Assets" do
    test "list/0 returns tradable assets" do
      assert {:ok, assets} = Assets.list(status: "active", asset_class: "us_equity")
      assert is_list(assets)
      assert length(assets) > 0
      IO.puts("  Active US equity assets: #{length(assets)}")
    end

    test "get/1 returns specific asset" do
      assert {:ok, asset} = Assets.get("AAPL")
      assert asset.symbol == "AAPL"
      assert asset.name != nil
      assert asset.tradable == true
      IO.puts("  AAPL: #{asset.name}")
      IO.puts("  Tradable: #{asset.tradable}, Fractionable: #{asset.fractionable}")
    end
  end

  # ============================================================================
  # Positions
  # ============================================================================

  describe "Positions" do
    test "list/0 returns open positions" do
      assert {:ok, positions} = Positions.list()
      assert is_list(positions)
      IO.puts("  Open positions: #{length(positions)}")

      Enum.each(positions, fn pos ->
        IO.puts("    #{pos.symbol}: #{pos.qty} shares @ $#{pos.avg_entry_price}")
      end)
    end
  end

  # ============================================================================
  # Watchlists
  # ============================================================================

  describe "Watchlists" do
    @test_watchlist_name "AlpaEx_Integration_Test"

    test "CRUD operations" do
      # Clean up any existing test watchlist
      case Watchlists.get_by_name(@test_watchlist_name) do
        {:ok, existing} -> Watchlists.delete(existing.id)
        _ -> :ok
      end

      # Create
      assert {:ok, watchlist} = Watchlists.create(
        name: @test_watchlist_name,
        symbols: ["AAPL", "MSFT"]
      )
      assert watchlist.name == @test_watchlist_name
      IO.puts("  Created watchlist: #{watchlist.id}")

      # List
      assert {:ok, watchlists} = Watchlists.list()
      assert Enum.any?(watchlists, &(&1.name == @test_watchlist_name))
      IO.puts("  Total watchlists: #{length(watchlists)}")

      # Get
      assert {:ok, fetched} = Watchlists.get(watchlist.id)
      assert fetched.name == @test_watchlist_name
      IO.puts("  Fetched watchlist with #{length(fetched.assets || [])} assets")

      # Add symbol
      assert {:ok, updated} = Watchlists.add_symbol(watchlist.id, "GOOGL")
      IO.puts("  Added GOOGL to watchlist")

      # Remove symbol
      assert {:ok, _} = Watchlists.remove_symbol(watchlist.id, "GOOGL")
      IO.puts("  Removed GOOGL from watchlist")

      # Re-fetch to get current state
      assert {:ok, current} = Watchlists.get(watchlist.id)

      # Update - use PUT semantics (provide all symbols)
      new_name = "#{@test_watchlist_name}_Renamed"
      case Watchlists.update(current.id, name: new_name) do
        {:ok, renamed} ->
          assert renamed.name == new_name
          IO.puts("  Renamed watchlist")
          # Delete using renamed ID
          assert {:ok, :deleted} = Watchlists.delete(renamed.id)

        {:error, _} ->
          # Some API versions don't support rename, just delete
          IO.puts("  Update not supported, skipping rename")
          assert {:ok, _} = Watchlists.delete(current.id)
      end
      IO.puts("  Deleted watchlist")
    end
  end

  # ============================================================================
  # Orders
  # ============================================================================

  describe "Orders" do
    test "list/0 returns orders" do
      assert {:ok, orders} = Orders.list(status: "all", limit: 10)
      assert is_list(orders)
      IO.puts("  Recent orders: #{length(orders)}")
    end

    test "place and cancel limit order" do
      # Place a limit order far from market price (won't fill)
      assert {:ok, order} = Orders.place(
        symbol: "AAPL",
        qty: 1,
        side: "buy",
        type: "limit",
        limit_price: "1.00",  # Very low, won't fill
        time_in_force: "day"
      )

      assert order.symbol == "AAPL"
      assert order.side == :buy
      assert order.type == "limit" or order.order_type == :limit
      IO.puts("  Placed order: #{order.id}")
      IO.puts("  Status: #{order.status}")

      # Give API a moment
      Process.sleep(500)

      # Cancel the order
      assert {:ok, _} = Orders.cancel(order.id)
      IO.puts("  Cancelled order")

      # Verify cancellation
      Process.sleep(500)
      assert {:ok, cancelled} = Orders.get(order.id)
      assert cancelled.status in [:canceled, :pending_cancel]
      IO.puts("  Final status: #{cancelled.status}")
    end

    test "cancel_all/0 cancels all open orders" do
      assert {:ok, result} = Orders.cancel_all()
      IO.puts("  Cancel all result: #{inspect(result)}")
    end
  end
end
