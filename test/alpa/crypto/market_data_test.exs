defmodule Alpa.Crypto.MarketDataTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{Bar, Quote, Snapshot, Trade}
  alias Alpa.Test.MockClient
  alias Alpa.Crypto.MarketData

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  # ============================================================================
  # Test data
  # ============================================================================

  @bar_data %{
    "t" => "2024-01-15T05:00:00Z",
    "o" => "42500.00",
    "h" => "43100.50",
    "l" => "42200.75",
    "c" => "42900.25",
    "v" => 1234,
    "n" => 567,
    "vw" => "42750.00"
  }

  @bar_data_2 %{
    "t" => "2024-01-16T05:00:00Z",
    "o" => "42900.25",
    "h" => "43500.00",
    "l" => "42800.00",
    "c" => "43200.50",
    "v" => 2345,
    "n" => 890,
    "vw" => "43100.00"
  }

  @quote_data %{
    "t" => "2024-01-15T14:30:00Z",
    "bp" => "42899.50",
    "bs" => 10,
    "ap" => "42900.25",
    "as" => 5
  }

  @quote_data_2 %{
    "t" => "2024-01-15T14:30:01Z",
    "bp" => "42901.00",
    "bs" => 8,
    "ap" => "42902.50",
    "as" => 3
  }

  @trade_data %{
    "t" => "2024-01-15T14:30:00Z",
    "p" => "42900.00",
    "s" => 15
  }

  @trade_data_2 %{
    "t" => "2024-01-15T14:30:01Z",
    "p" => "42905.50",
    "s" => 7
  }

  @snapshot_data %{
    "latestTrade" => %{
      "t" => "2024-01-15T14:30:00Z",
      "p" => "42900.00",
      "s" => 15
    },
    "latestQuote" => %{
      "t" => "2024-01-15T14:30:00Z",
      "bp" => "42899.50",
      "bs" => 10,
      "ap" => "42900.25",
      "as" => 5
    },
    "minuteBar" => %{
      "t" => "2024-01-15T14:30:00Z",
      "o" => "42880.00",
      "h" => "42910.00",
      "l" => "42875.00",
      "c" => "42900.00",
      "v" => 100,
      "n" => 25,
      "vw" => "42890.00"
    },
    "dailyBar" => %{
      "t" => "2024-01-15T05:00:00Z",
      "o" => "42500.00",
      "h" => "43100.50",
      "l" => "42200.75",
      "c" => "42900.25",
      "v" => 1234,
      "n" => 567,
      "vw" => "42750.00"
    },
    "prevDailyBar" => %{
      "t" => "2024-01-14T05:00:00Z",
      "o" => "42100.00",
      "h" => "42600.00",
      "l" => "41900.00",
      "c" => "42500.00",
      "v" => 999,
      "n" => 432,
      "vw" => "42300.00"
    }
  }

  # ============================================================================
  # bars/2
  # ============================================================================

  describe "bars/2" do
    test "requires credentials" do
      result = MarketData.bars("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Bar structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, %{"bars" => %{"BTC/USD" => [@bar_data, @bar_data_2]}}}
      )

      {:ok, bars} = MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")

      assert length(bars) == 2
      assert [%Bar{} = bar1, %Bar{} = bar2] = bars

      assert bar1.symbol == "BTC/USD"
      assert Decimal.eq?(bar1.open, Decimal.new("42500.00"))
      assert Decimal.eq?(bar1.high, Decimal.new("43100.50"))
      assert Decimal.eq?(bar1.low, Decimal.new("42200.75"))
      assert Decimal.eq?(bar1.close, Decimal.new("42900.25"))
      assert bar1.volume == 1234
      assert bar1.trade_count == 567
      assert Decimal.eq?(bar1.vwap, Decimal.new("42750.00"))

      assert bar2.symbol == "BTC/USD"
      assert Decimal.eq?(bar2.open, Decimal.new("42900.25"))
    end

    test "returns single bar when response has a map instead of list" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, %{"bars" => %{"BTC/USD" => @bar_data}}}
      )

      {:ok, bars} = MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")

      assert length(bars) == 1
      assert [%Bar{symbol: "BTC/USD"}] = bars
    end

    test "returns empty list when symbol not found in bars" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, %{"bars" => %{"ETH/USD" => [@bar_data]}}}
      )

      {:ok, bars} = MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")

      assert bars == []
    end

    test "returns empty list when bars is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, %{"bars" => nil}}
      )

      {:ok, bars} = MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")

      assert bars == []
    end

    test "returns empty list when response has no bars key" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, %{"other" => "data"}}
      )

      {:ok, bars} = MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")

      assert bars == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} =
        MarketData.bars("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # latest_bars/2
  # ============================================================================

  describe "latest_bars/2" do
    test "requires credentials" do
      result = MarketData.latest_bars("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Bar structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/bars",
        {:ok, %{"bars" => %{"BTC/USD" => [@bar_data]}}}
      )

      {:ok, bars} = MarketData.latest_bars("BTC/USD", api_key: "test", api_secret: "test")

      assert length(bars) == 1
      assert [%Bar{} = bar] = bars
      assert bar.symbol == "BTC/USD"
      assert Decimal.eq?(bar.open, Decimal.new("42500.00"))
      assert Decimal.eq?(bar.high, Decimal.new("43100.50"))
      assert Decimal.eq?(bar.low, Decimal.new("42200.75"))
      assert Decimal.eq?(bar.close, Decimal.new("42900.25"))
      assert bar.volume == 1234
      assert bar.trade_count == 567
      assert Decimal.eq?(bar.vwap, Decimal.new("42750.00"))
    end

    test "returns single bar when response has a map instead of list" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/bars",
        {:ok, %{"bars" => %{"BTC/USD" => @bar_data}}}
      )

      {:ok, bars} = MarketData.latest_bars("BTC/USD", api_key: "test", api_secret: "test")

      assert length(bars) == 1
      assert [%Bar{symbol: "BTC/USD"}] = bars
    end

    test "returns empty list when bars is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/bars",
        {:ok, %{"bars" => nil}}
      )

      {:ok, bars} = MarketData.latest_bars("BTC/USD", api_key: "test", api_secret: "test")

      assert bars == []
    end

    test "returns empty list when symbol not in response" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/bars",
        {:ok, %{"bars" => %{"ETH/USD" => [@bar_data]}}}
      )

      {:ok, bars} = MarketData.latest_bars("BTC/USD", api_key: "test", api_secret: "test")

      assert bars == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/bars",
        {:error, Error.from_response(429, %{"message" => "Rate limited"})}
      )

      {:error, %Error{type: :rate_limited}} =
        MarketData.latest_bars("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # quotes/2
  # ============================================================================

  describe "quotes/2" do
    test "requires credentials" do
      result = MarketData.quotes("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Quote structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, %{"quotes" => %{"BTC/USD" => [@quote_data, @quote_data_2]}}}
      )

      {:ok, quotes} = MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert length(quotes) == 2
      assert [%Quote{} = q1, %Quote{} = q2] = quotes

      assert q1.symbol == "BTC/USD"
      assert Decimal.eq?(q1.bid_price, Decimal.new("42899.50"))
      assert q1.bid_size == 10
      assert Decimal.eq?(q1.ask_price, Decimal.new("42900.25"))
      assert q1.ask_size == 5

      assert q2.symbol == "BTC/USD"
      assert Decimal.eq?(q2.bid_price, Decimal.new("42901.00"))
      assert q2.bid_size == 8
      assert Decimal.eq?(q2.ask_price, Decimal.new("42902.50"))
      assert q2.ask_size == 3
    end

    test "returns single quote when response has a map instead of list" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, %{"quotes" => %{"BTC/USD" => @quote_data}}}
      )

      {:ok, quotes} = MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert length(quotes) == 1
      assert [%Quote{symbol: "BTC/USD"}] = quotes
    end

    test "returns empty list when quotes is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, %{"quotes" => nil}}
      )

      {:ok, quotes} = MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert quotes == []
    end

    test "returns empty list when symbol not in response" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, %{"quotes" => %{"ETH/USD" => [@quote_data]}}}
      )

      {:ok, quotes} = MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert quotes == []
    end

    test "returns empty list when response has no quotes key" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, %{"other" => "data"}}
      )

      {:ok, quotes} = MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert quotes == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} =
        MarketData.quotes("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # latest_quotes/2
  # ============================================================================

  describe "latest_quotes/2" do
    test "requires credentials" do
      result = MarketData.latest_quotes("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Quote structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/quotes",
        {:ok, %{"quotes" => %{"BTC/USD" => [@quote_data]}}}
      )

      {:ok, quotes} = MarketData.latest_quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert length(quotes) == 1
      assert [%Quote{} = q] = quotes
      assert q.symbol == "BTC/USD"
      assert Decimal.eq?(q.bid_price, Decimal.new("42899.50"))
      assert q.bid_size == 10
      assert Decimal.eq?(q.ask_price, Decimal.new("42900.25"))
      assert q.ask_size == 5
    end

    test "returns empty list when quotes is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/quotes",
        {:ok, %{"quotes" => nil}}
      )

      {:ok, quotes} = MarketData.latest_quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert quotes == []
    end

    test "returns empty list when symbol not in response" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/quotes",
        {:ok, %{"quotes" => %{"ETH/USD" => [@quote_data]}}}
      )

      {:ok, quotes} = MarketData.latest_quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert quotes == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/quotes",
        {:error, Error.from_response(500, %{"message" => "Internal Server Error"})}
      )

      {:error, %Error{type: :server_error}} =
        MarketData.latest_quotes("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # trades/2
  # ============================================================================

  describe "trades/2" do
    test "requires credentials" do
      result = MarketData.trades("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Trade structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, %{"trades" => %{"BTC/USD" => [@trade_data, @trade_data_2]}}}
      )

      {:ok, trades} = MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")

      assert length(trades) == 2
      assert [%Trade{} = t1, %Trade{} = t2] = trades

      assert t1.symbol == "BTC/USD"
      assert Decimal.eq?(t1.price, Decimal.new("42900.00"))
      assert t1.size == 15

      assert t2.symbol == "BTC/USD"
      assert Decimal.eq?(t2.price, Decimal.new("42905.50"))
      assert t2.size == 7
    end

    test "returns single trade when response has a map instead of list" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, %{"trades" => %{"BTC/USD" => @trade_data}}}
      )

      {:ok, trades} = MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")

      assert length(trades) == 1
      assert [%Trade{symbol: "BTC/USD"}] = trades
    end

    test "returns empty list when trades is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, %{"trades" => nil}}
      )

      {:ok, trades} = MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")

      assert trades == []
    end

    test "returns empty list when symbol not in response" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, %{"trades" => %{"ETH/USD" => [@trade_data]}}}
      )

      {:ok, trades} = MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")

      assert trades == []
    end

    test "returns empty list when response has no trades key" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, %{"other" => "data"}}
      )

      {:ok, trades} = MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")

      assert trades == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:error, Error.from_response(403, %{"message" => "Forbidden"})}
      )

      {:error, %Error{type: :forbidden}} =
        MarketData.trades("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # latest_trades/2
  # ============================================================================

  describe "latest_trades/2" do
    test "requires credentials" do
      result = MarketData.latest_trades("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Trade structs" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/trades",
        {:ok, %{"trades" => %{"BTC/USD" => [@trade_data]}}}
      )

      {:ok, trades} = MarketData.latest_trades("BTC/USD", api_key: "test", api_secret: "test")

      assert length(trades) == 1
      assert [%Trade{} = t] = trades
      assert t.symbol == "BTC/USD"
      assert Decimal.eq?(t.price, Decimal.new("42900.00"))
      assert t.size == 15
    end

    test "returns empty list when trades is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/trades",
        {:ok, %{"trades" => nil}}
      )

      {:ok, trades} = MarketData.latest_trades("BTC/USD", api_key: "test", api_secret: "test")

      assert trades == []
    end

    test "returns empty list when symbol not in response" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/trades",
        {:ok, %{"trades" => %{"ETH/USD" => [@trade_data]}}}
      )

      {:ok, trades} = MarketData.latest_trades("BTC/USD", api_key: "test", api_secret: "test")

      assert trades == []
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/latest/trades",
        {:error, Error.from_response(422, %{"message" => "Invalid parameter"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        MarketData.latest_trades("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # snapshots/2
  # ============================================================================

  describe "snapshots/2" do
    test "requires credentials with single symbol" do
      result = MarketData.snapshots("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "requires credentials with multiple symbols" do
      result = MarketData.snapshots(["BTC/USD", "ETH/USD"], api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed Snapshot structs for single symbol" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, %{"snapshots" => %{"BTC/USD" => @snapshot_data}}}
      )

      {:ok, snapshots} = MarketData.snapshots("BTC/USD", api_key: "test", api_secret: "test")

      assert is_map(snapshots)
      assert map_size(snapshots) == 1
      assert %Snapshot{} = snapshot = snapshots["BTC/USD"]

      assert snapshot.symbol == "BTC/USD"

      assert %Trade{} = snapshot.latest_trade
      assert snapshot.latest_trade.symbol == "BTC/USD"
      assert Decimal.eq?(snapshot.latest_trade.price, Decimal.new("42900.00"))
      assert snapshot.latest_trade.size == 15

      assert %Quote{} = snapshot.latest_quote
      assert snapshot.latest_quote.symbol == "BTC/USD"
      assert Decimal.eq?(snapshot.latest_quote.bid_price, Decimal.new("42899.50"))
      assert snapshot.latest_quote.bid_size == 10
      assert Decimal.eq?(snapshot.latest_quote.ask_price, Decimal.new("42900.25"))
      assert snapshot.latest_quote.ask_size == 5

      assert %Bar{} = snapshot.minute_bar
      assert snapshot.minute_bar.symbol == "BTC/USD"
      assert Decimal.eq?(snapshot.minute_bar.open, Decimal.new("42880.00"))

      assert %Bar{} = snapshot.daily_bar
      assert snapshot.daily_bar.symbol == "BTC/USD"
      assert Decimal.eq?(snapshot.daily_bar.open, Decimal.new("42500.00"))

      assert %Bar{} = snapshot.prev_daily_bar
      assert snapshot.prev_daily_bar.symbol == "BTC/USD"
      assert Decimal.eq?(snapshot.prev_daily_bar.open, Decimal.new("42100.00"))
    end

    test "returns parsed Snapshot structs for multiple symbols" do
      eth_snapshot = %{
        "latestTrade" => %{
          "t" => "2024-01-15T14:30:00Z",
          "p" => "2500.00",
          "s" => 50
        },
        "latestQuote" => %{
          "t" => "2024-01-15T14:30:00Z",
          "bp" => "2499.50",
          "bs" => 20,
          "ap" => "2500.25",
          "as" => 15
        },
        "minuteBar" => %{
          "t" => "2024-01-15T14:30:00Z",
          "o" => "2495.00",
          "h" => "2505.00",
          "l" => "2490.00",
          "c" => "2500.00",
          "v" => 200,
          "n" => 50,
          "vw" => "2498.00"
        },
        "dailyBar" => nil,
        "prevDailyBar" => nil
      }

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, %{"snapshots" => %{"BTC/USD" => @snapshot_data, "ETH/USD" => eth_snapshot}}}
      )

      {:ok, snapshots} =
        MarketData.snapshots(["BTC/USD", "ETH/USD"], api_key: "test", api_secret: "test")

      assert map_size(snapshots) == 2
      assert %Snapshot{symbol: "BTC/USD"} = snapshots["BTC/USD"]
      assert %Snapshot{symbol: "ETH/USD"} = snapshots["ETH/USD"]

      eth = snapshots["ETH/USD"]
      assert Decimal.eq?(eth.latest_trade.price, Decimal.new("2500.00"))
      assert eth.daily_bar == nil
      assert eth.prev_daily_bar == nil
    end

    test "returns empty map when snapshots is nil" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, %{"snapshots" => nil}}
      )

      {:ok, snapshots} = MarketData.snapshots("BTC/USD", api_key: "test", api_secret: "test")

      assert snapshots == %{}
    end

    test "returns empty map when response has no snapshots key" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, %{"other" => "data"}}
      )

      {:ok, snapshots} = MarketData.snapshots("BTC/USD", api_key: "test", api_secret: "test")

      assert snapshots == %{}
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} =
        MarketData.snapshots("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # get_bars/2 (raw)
  # ============================================================================

  describe "get_bars/2" do
    test "requires credentials" do
      result = MarketData.get_bars("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns raw bar data" do
      raw_response = %{"bars" => %{"BTC/USD" => [@bar_data]}}

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:ok, raw_response}
      )

      {:ok, data} = MarketData.get_bars("BTC/USD", api_key: "test", api_secret: "test")

      assert data == raw_response
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/bars",
        {:error, Error.from_response(404, %{"message" => "Not found"})}
      )

      {:error, %Error{type: :not_found}} =
        MarketData.get_bars("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # get_quotes/2 (raw)
  # ============================================================================

  describe "get_quotes/2" do
    test "requires credentials" do
      result = MarketData.get_quotes("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns raw quote data" do
      raw_response = %{"quotes" => %{"BTC/USD" => [@quote_data]}}

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:ok, raw_response}
      )

      {:ok, data} = MarketData.get_quotes("BTC/USD", api_key: "test", api_secret: "test")

      assert data == raw_response
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/quotes",
        {:error, Error.from_response(404, %{"message" => "Not found"})}
      )

      {:error, %Error{type: :not_found}} =
        MarketData.get_quotes("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # get_trades/2 (raw)
  # ============================================================================

  describe "get_trades/2" do
    test "requires credentials" do
      result = MarketData.get_trades("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns raw trade data" do
      raw_response = %{"trades" => %{"BTC/USD" => [@trade_data]}}

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:ok, raw_response}
      )

      {:ok, data} = MarketData.get_trades("BTC/USD", api_key: "test", api_secret: "test")

      assert data == raw_response
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/trades",
        {:error, Error.from_response(404, %{"message" => "Not found"})}
      )

      {:error, %Error{type: :not_found}} =
        MarketData.get_trades("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # get_snapshots/2 (raw)
  # ============================================================================

  describe "get_snapshots/2" do
    test "requires credentials" do
      result = MarketData.get_snapshots("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns raw snapshot data with single symbol" do
      raw_response = %{"snapshots" => %{"BTC/USD" => @snapshot_data}}

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, raw_response}
      )

      {:ok, data} = MarketData.get_snapshots("BTC/USD", api_key: "test", api_secret: "test")

      assert data == raw_response
    end

    test "returns raw snapshot data with multiple symbols" do
      raw_response = %{
        "snapshots" => %{
          "BTC/USD" => @snapshot_data,
          "ETH/USD" => @snapshot_data
        }
      }

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:ok, raw_response}
      )

      {:ok, data} =
        MarketData.get_snapshots(["BTC/USD", "ETH/USD"], api_key: "test", api_secret: "test")

      assert data == raw_response
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/snapshots",
        {:error, Error.from_response(500, %{"message" => "Server error"})}
      )

      {:error, %Error{type: :server_error}} =
        MarketData.get_snapshots("BTC/USD", api_key: "test", api_secret: "test")
    end
  end

  # ============================================================================
  # get_orderbook/2
  # ============================================================================

  describe "get_orderbook/2" do
    test "requires credentials" do
      result = MarketData.get_orderbook("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns orderbook data for single symbol" do
      raw_response = %{
        "orderbooks" => %{
          "BTC/USD" => %{
            "t" => "2024-01-15T14:30:00Z",
            "b" => [
              %{"p" => "42899.00", "s" => 1.5},
              %{"p" => "42898.00", "s" => 2.0}
            ],
            "a" => [
              %{"p" => "42901.00", "s" => 1.0},
              %{"p" => "42902.00", "s" => 3.0}
            ]
          }
        }
      }

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/orderbooks",
        {:ok, raw_response}
      )

      {:ok, data} = MarketData.get_orderbook("BTC/USD", api_key: "test", api_secret: "test")

      assert data == raw_response
      assert is_map(data["orderbooks"]["BTC/USD"])
      assert length(data["orderbooks"]["BTC/USD"]["b"]) == 2
      assert length(data["orderbooks"]["BTC/USD"]["a"]) == 2
    end

    test "returns orderbook data for multiple symbols" do
      raw_response = %{
        "orderbooks" => %{
          "BTC/USD" => %{
            "t" => "2024-01-15T14:30:00Z",
            "b" => [%{"p" => "42899.00", "s" => 1.5}],
            "a" => [%{"p" => "42901.00", "s" => 1.0}]
          },
          "ETH/USD" => %{
            "t" => "2024-01-15T14:30:00Z",
            "b" => [%{"p" => "2499.00", "s" => 10.0}],
            "a" => [%{"p" => "2501.00", "s" => 5.0}]
          }
        }
      }

      MockClient.mock_get_data(
        "/v1beta3/crypto/us/orderbooks",
        {:ok, raw_response}
      )

      {:ok, data} =
        MarketData.get_orderbook(["BTC/USD", "ETH/USD"], api_key: "test", api_secret: "test")

      assert data == raw_response
      assert Map.has_key?(data["orderbooks"], "BTC/USD")
      assert Map.has_key?(data["orderbooks"], "ETH/USD")
    end

    test "handles API error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/orderbooks",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} =
        MarketData.get_orderbook("BTC/USD", api_key: "test", api_secret: "test")
    end

    test "handles rate limiting error" do
      MockClient.mock_get_data(
        "/v1beta3/crypto/us/orderbooks",
        {:error, Error.from_response(429, %{"message" => "Too many requests"})}
      )

      {:error, %Error{type: :rate_limited}} =
        MarketData.get_orderbook("BTC/USD", api_key: "test", api_secret: "test")
    end
  end
end
