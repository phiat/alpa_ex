defmodule Alpa.Trading.OrdersTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Order
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Orders

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @order_response %{
    "id" => "order-123",
    "client_order_id" => "client-456",
    "symbol" => "AAPL",
    "asset_class" => "us_equity",
    "qty" => "10",
    "filled_qty" => "0",
    "side" => "buy",
    "order_type" => "market",
    "type" => "market",
    "time_in_force" => "day",
    "status" => "new",
    "created_at" => "2024-01-15T10:30:00Z",
    "submitted_at" => "2024-01-15T10:30:00Z"
  }

  @limit_order_response %{
    "id" => "order-limit-789",
    "client_order_id" => "client-limit-012",
    "symbol" => "MSFT",
    "asset_class" => "us_equity",
    "qty" => "5",
    "filled_qty" => "0",
    "side" => "buy",
    "order_type" => "limit",
    "type" => "limit",
    "time_in_force" => "gtc",
    "limit_price" => "400.00",
    "status" => "new",
    "created_at" => "2024-01-15T11:00:00Z",
    "submitted_at" => "2024-01-15T11:00:00Z"
  }

  describe "place/1" do
    test "requires credentials" do
      result =
        Orders.place(
          symbol: "AAPL",
          qty: 10,
          side: "buy",
          type: "market",
          time_in_force: "day",
          api_key: nil,
          api_secret: nil
        )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a market order" do
      MockClient.mock_post("/v2/orders", {:ok, @order_response})

      {:ok, order} =
        Orders.place(
          symbol: "AAPL",
          qty: 10,
          side: "buy",
          type: "market",
          time_in_force: "day",
          api_key: "test",
          api_secret: "test"
        )

      assert %Order{} = order
      assert order.id == "order-123"
      assert order.symbol == "AAPL"
      assert order.side == :buy
      assert order.order_type == :market
      assert order.status == :new
    end

    test "places a limit order" do
      MockClient.mock_post("/v2/orders", {:ok, @limit_order_response})

      {:ok, order} =
        Orders.place(
          symbol: "MSFT",
          qty: 5,
          side: "buy",
          type: "limit",
          limit_price: "400.00",
          time_in_force: "gtc",
          api_key: "test",
          api_secret: "test"
        )

      assert %Order{} = order
      assert order.order_type == :limit
      assert Decimal.eq?(order.limit_price, Decimal.new("400.00"))
    end

    test "handles API error" do
      MockClient.mock_post(
        "/v2/orders",
        {:error, Error.from_response(422, %{"message" => "insufficient qty"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        Orders.place(
          symbol: "AAPL",
          qty: 999_999,
          side: "buy",
          type: "market",
          time_in_force: "day",
          api_key: "test",
          api_secret: "test"
        )
    end
  end

  describe "list/1" do
    test "requires credentials" do
      result = Orders.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of orders" do
      MockClient.mock_get("/v2/orders", {:ok, [@order_response, @limit_order_response]})

      {:ok, orders} = Orders.list(api_key: "test", api_secret: "test")

      assert length(orders) == 2
      assert %Order{} = hd(orders)
      assert hd(orders).id == "order-123"
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/orders", {:ok, []})
      {:ok, orders} = Orders.list(api_key: "test", api_secret: "test")
      assert orders == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/orders", {:ok, %{"error" => "unexpected"}})

      {:error, %Error{type: :invalid_response}} =
        Orders.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Orders.get("order-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single order" do
      MockClient.mock_get("/v2/orders/order-123", {:ok, @order_response})

      {:ok, order} = Orders.get("order-123", api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.id == "order-123"
      assert order.symbol == "AAPL"
    end

    test "handles not found" do
      MockClient.mock_get(
        "/v2/orders/nonexistent",
        {:error, Error.from_response(404, %{"message" => "order not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Orders.get("nonexistent", api_key: "test", api_secret: "test")
    end
  end

  describe "get_by_client_id/2" do
    test "requires credentials" do
      result = Orders.get_by_client_id("client-456", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns an order by client order ID" do
      MockClient.mock_get("/v2/orders/by_client_order_id", {:ok, @order_response})

      {:ok, order} =
        Orders.get_by_client_id("client-456", api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.client_order_id == "client-456"
    end
  end

  describe "replace/2" do
    test "requires credentials" do
      result =
        Orders.replace("order-123",
          qty: 20,
          api_key: nil,
          api_secret: nil
        )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "replaces an order" do
      replaced = Map.put(@order_response, "qty", "20")
      MockClient.mock_patch("/v2/orders/order-123", {:ok, replaced})

      {:ok, order} =
        Orders.replace("order-123",
          qty: 20,
          api_key: "test",
          api_secret: "test"
        )

      assert %Order{} = order
      assert Decimal.eq?(order.qty, Decimal.new("20"))
    end

    test "handles API error on replace" do
      MockClient.mock_patch(
        "/v2/orders/order-123",
        {:error, Error.from_response(422, %{"message" => "cannot replace filled order"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        Orders.replace("order-123",
          qty: 20,
          api_key: "test",
          api_secret: "test"
        )
    end
  end

  describe "cancel/2" do
    test "requires credentials" do
      result = Orders.cancel("order-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "cancels an order" do
      MockClient.mock_delete("/v2/orders/order-123", {:ok, :deleted})

      assert {:ok, :deleted} = Orders.cancel("order-123", api_key: "test", api_secret: "test")
    end

    test "handles cancel of non-existent order" do
      MockClient.mock_delete(
        "/v2/orders/nonexistent",
        {:error, Error.from_response(404, %{"message" => "order not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Orders.cancel("nonexistent", api_key: "test", api_secret: "test")
    end
  end

  describe "cancel_all/1" do
    test "requires credentials" do
      result = Orders.cancel_all(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "cancels all orders" do
      MockClient.mock_delete("/v2/orders", {:ok, [%{"id" => "order-1", "status" => 200}]})

      {:ok, results} = Orders.cancel_all(api_key: "test", api_secret: "test")
      assert is_list(results)
    end
  end

  describe "buy/3" do
    test "requires credentials" do
      result = Orders.buy("AAPL", 10, api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a market buy order" do
      MockClient.mock_post("/v2/orders", {:ok, @order_response})

      {:ok, order} = Orders.buy("AAPL", 10, api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.side == :buy
      assert order.order_type == :market
    end
  end

  describe "sell/3" do
    test "requires credentials" do
      result = Orders.sell("AAPL", 10, api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "places a market sell order" do
      sell_response = %{@order_response | "side" => "sell"}
      MockClient.mock_post("/v2/orders", {:ok, sell_response})

      {:ok, order} = Orders.sell("AAPL", 10, api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.side == :sell
    end
  end
end
