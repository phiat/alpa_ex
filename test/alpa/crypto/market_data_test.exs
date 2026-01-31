defmodule Alpa.Crypto.MarketDataTest do
  use ExUnit.Case, async: true

  alias Alpa.Crypto.MarketData
  alias Alpa.Error

  describe "bars/2" do
    test "requires credentials" do
      result = MarketData.bars("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest_bars/2" do
    test "requires credentials" do
      result = MarketData.latest_bars("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "quotes/2" do
    test "requires credentials" do
      result = MarketData.quotes("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest_quotes/2" do
    test "requires credentials" do
      result = MarketData.latest_quotes("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "trades/2" do
    test "requires credentials" do
      result = MarketData.trades("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest_trades/2" do
    test "requires credentials" do
      result = MarketData.latest_trades("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "snapshots/2" do
    test "requires credentials with single symbol" do
      result = MarketData.snapshots("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "requires credentials with multiple symbols" do
      result = MarketData.snapshots(["BTC/USD", "ETH/USD"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_bars/2" do
    test "requires credentials" do
      result = MarketData.get_bars("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_quotes/2" do
    test "requires credentials" do
      result = MarketData.get_quotes("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_trades/2" do
    test "requires credentials" do
      result = MarketData.get_trades("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_snapshots/2" do
    test "requires credentials" do
      result = MarketData.get_snapshots("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_orderbook/2" do
    test "requires credentials" do
      result = MarketData.get_orderbook("BTC/USD", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
