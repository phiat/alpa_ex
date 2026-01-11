defmodule Alpa.Trading.OrdersTest do
  use ExUnit.Case, async: true

  alias Alpa.Error
  alias Alpa.Trading.Orders

  describe "place/1" do
    test "requires credentials" do
      result = Orders.place(
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
  end

  describe "list/1" do
    test "requires credentials" do
      result = Orders.list(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Orders.get("order-123", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "cancel/2" do
    test "requires credentials" do
      result = Orders.cancel("order-123", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "buy/3" do
    test "requires credentials" do
      result = Orders.buy("AAPL", 10, api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "sell/3" do
    test "requires credentials" do
      result = Orders.sell("AAPL", 10, api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
