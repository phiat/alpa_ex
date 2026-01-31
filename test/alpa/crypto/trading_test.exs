defmodule Alpa.Crypto.TradingTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{Asset, Order, Position}
  alias Alpa.Test.MockClient
  alias Alpa.Crypto.Trading

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @btc_asset %{
    "id" => "asset-btc-001",
    "class" => "crypto",
    "symbol" => "BTC/USD",
    "name" => "Bitcoin",
    "status" => "active",
    "tradable" => true,
    "exchange" => "CRYPTO",
    "fractionable" => true,
    "min_order_size" => "0.0001",
    "min_trade_increment" => "0.0001",
    "price_increment" => "0.01"
  }

  @btc_position %{
    "asset_id" => "asset-btc-001",
    "symbol" => "BTC/USD",
    "exchange" => "CRYPTO",
    "asset_class" => "crypto",
    "qty" => "0.5",
    "avg_entry_price" => "42000.00",
    "side" => "long",
    "market_value" => "21500.00",
    "cost_basis" => "21000.00",
    "unrealized_pl" => "500.00",
    "unrealized_plpc" => "0.0238",
    "current_price" => "43000.00",
    "lastday_price" => "42500.00",
    "change_today" => "0.0118"
  }

  @order_response %{
    "id" => "order-crypto-123",
    "client_order_id" => "client-456",
    "symbol" => "BTC/USD",
    "asset_class" => "crypto",
    "qty" => "0.01",
    "side" => "buy",
    "order_type" => "market",
    "type" => "market",
    "time_in_force" => "gtc",
    "status" => "new",
    "created_at" => "2024-01-15T10:30:00Z"
  }

  describe "assets/1" do
    test "requires credentials" do
      result = Trading.assets(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns crypto assets" do
      MockClient.mock_get("/v2/assets", {:ok, [@btc_asset]})

      {:ok, assets} = Trading.assets(api_key: "test", api_secret: "test")

      assert length(assets) == 1
      assert %Asset{} = hd(assets)
      assert hd(assets).symbol == "BTC/USD"
      assert hd(assets).class == :crypto
    end

    test "handles empty list" do
      MockClient.mock_get("/v2/assets", {:ok, []})
      {:ok, assets} = Trading.assets(api_key: "test", api_secret: "test")
      assert assets == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/assets", {:ok, %{"error" => "unexpected"}})
      {:error, %Error{type: :invalid_response}} = Trading.assets(api_key: "test", api_secret: "test")
    end
  end

  describe "asset/2" do
    test "requires credentials" do
      result = Trading.asset("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single crypto asset" do
      MockClient.mock_get("/v2/assets/BTC%2FUSD", {:ok, @btc_asset})

      {:ok, asset} = Trading.asset("BTC/USD", api_key: "test", api_secret: "test")

      assert %Asset{} = asset
      assert asset.symbol == "BTC/USD"
      assert asset.class == :crypto
      assert asset.tradable == true
    end
  end

  describe "positions/1" do
    test "requires credentials" do
      result = Trading.positions(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns only crypto positions" do
      equity_position = %{
        "asset_id" => "asset-aapl-001",
        "symbol" => "AAPL",
        "asset_class" => "us_equity",
        "qty" => "10",
        "side" => "long"
      }

      MockClient.mock_get("/v2/positions", {:ok, [equity_position, @btc_position]})

      {:ok, positions} = Trading.positions(api_key: "test", api_secret: "test")

      assert length(positions) == 1
      assert %Position{} = hd(positions)
      assert hd(positions).symbol == "BTC/USD"
    end

    test "returns empty list when no crypto positions" do
      equity_position = %{
        "asset_id" => "asset-aapl-001",
        "symbol" => "AAPL",
        "asset_class" => "us_equity",
        "qty" => "10",
        "side" => "long"
      }

      MockClient.mock_get("/v2/positions", {:ok, [equity_position]})

      {:ok, positions} = Trading.positions(api_key: "test", api_secret: "test")

      assert positions == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/positions", {:ok, %{"error" => "unexpected"}})
      {:error, %Error{type: :invalid_response}} = Trading.positions(api_key: "test", api_secret: "test")
    end
  end

  describe "position/2" do
    test "requires credentials" do
      result = Trading.position("BTC/USD", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single crypto position" do
      MockClient.mock_get("/v2/positions/BTC%2FUSD", {:ok, @btc_position})

      {:ok, position} = Trading.position("BTC/USD", api_key: "test", api_secret: "test")

      assert %Position{} = position
      assert position.symbol == "BTC/USD"
      assert Decimal.eq?(position.qty, Decimal.new("0.5"))
      assert Decimal.eq?(position.avg_entry_price, Decimal.new("42000.00"))
      assert position.side == :long
    end
  end

  describe "place_order/1" do
    test "requires credentials" do
      result = Trading.place_order(
        symbol: "BTC/USD",
        qty: "0.01",
        side: "buy",
        type: "market",
        time_in_force: "gtc",
        api_key: nil,
        api_secret: nil
      )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a crypto market order" do
      MockClient.mock_post("/v2/orders", {:ok, @order_response})

      {:ok, order} = Trading.place_order(
        symbol: "BTC/USD",
        qty: "0.01",
        side: "buy",
        type: "market",
        time_in_force: "gtc",
        api_key: "test",
        api_secret: "test"
      )

      assert %Order{} = order
      assert order.id == "order-crypto-123"
      assert order.symbol == "BTC/USD"
      assert order.side == :buy
      assert order.order_type == :market
      assert order.status == :new
    end

    test "places a crypto limit order" do
      limit_response = @order_response
        |> Map.put("order_type", "limit")
        |> Map.put("type", "limit")
        |> Map.put("limit_price", "40000.00")
      MockClient.mock_post("/v2/orders", {:ok, limit_response})

      {:ok, order} = Trading.place_order(
        symbol: "BTC/USD",
        qty: "0.1",
        side: "buy",
        type: "limit",
        limit_price: "40000",
        time_in_force: "gtc",
        api_key: "test",
        api_secret: "test"
      )

      assert order.order_type == :limit
      assert Decimal.eq?(order.limit_price, Decimal.new("40000.00"))
    end

    test "handles API error" do
      MockClient.mock_post("/v2/orders",
        {:error, Error.from_response(422, %{"message" => "insufficient balance"})})

      {:error, %Error{type: :unprocessable_entity}} = Trading.place_order(
        symbol: "BTC/USD",
        qty: "100",
        side: "buy",
        type: "market",
        time_in_force: "gtc",
        api_key: "test",
        api_secret: "test"
      )
    end
  end

  describe "buy/3" do
    test "requires credentials" do
      result = Trading.buy("BTC/USD", "0.01", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a buy market order" do
      MockClient.mock_post("/v2/orders", {:ok, @order_response})

      {:ok, order} = Trading.buy("BTC/USD", "0.01", api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.side == :buy
    end
  end

  describe "sell/3" do
    test "requires credentials" do
      result = Trading.sell("BTC/USD", "0.01", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a sell market order" do
      sell_response = %{@order_response | "side" => "sell"}
      MockClient.mock_post("/v2/orders", {:ok, sell_response})

      {:ok, order} = Trading.sell("BTC/USD", "0.01", api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.side == :sell
    end
  end
end
