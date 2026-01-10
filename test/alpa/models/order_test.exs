defmodule Alpa.Models.OrderTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Order

  describe "from_map/1" do
    test "parses order data" do
      data = %{
        "id" => "order-123",
        "client_order_id" => "client-456",
        "symbol" => "AAPL",
        "asset_class" => "us_equity",
        "qty" => "10",
        "filled_qty" => "0",
        "side" => "buy",
        "type" => "market",
        "time_in_force" => "day",
        "status" => "new",
        "extended_hours" => false,
        "created_at" => "2024-01-15T10:30:00Z"
      }

      order = Order.from_map(data)

      assert order.id == "order-123"
      assert order.client_order_id == "client-456"
      assert order.symbol == "AAPL"
      assert Decimal.eq?(order.qty, Decimal.new("10"))
      assert order.side == :buy
      assert order.order_type == :market
      assert order.time_in_force == :day
      assert order.status == :new
      assert order.extended_hours == false
    end

    test "parses side correctly" do
      assert Order.from_map(%{"side" => "buy"}).side == :buy
      assert Order.from_map(%{"side" => "sell"}).side == :sell
    end

    test "parses order type correctly" do
      assert Order.from_map(%{"type" => "market"}).order_type == :market
      assert Order.from_map(%{"type" => "limit"}).order_type == :limit
      assert Order.from_map(%{"type" => "stop"}).order_type == :stop
      assert Order.from_map(%{"type" => "stop_limit"}).order_type == :stop_limit
      assert Order.from_map(%{"type" => "trailing_stop"}).order_type == :trailing_stop
    end

    test "parses time in force correctly" do
      assert Order.from_map(%{"time_in_force" => "day"}).time_in_force == :day
      assert Order.from_map(%{"time_in_force" => "gtc"}).time_in_force == :gtc
      assert Order.from_map(%{"time_in_force" => "ioc"}).time_in_force == :ioc
      assert Order.from_map(%{"time_in_force" => "fok"}).time_in_force == :fok
    end

    test "parses order class correctly" do
      assert Order.from_map(%{"order_class" => ""}).order_class == :simple
      assert Order.from_map(%{"order_class" => nil}).order_class == :simple
      assert Order.from_map(%{"order_class" => "bracket"}).order_class == :bracket
      assert Order.from_map(%{"order_class" => "oco"}).order_class == :oco
      assert Order.from_map(%{"order_class" => "oto"}).order_class == :oto
    end

    test "parses legs for bracket orders" do
      data = %{
        "id" => "order-123",
        "order_class" => "bracket",
        "legs" => [
          %{"id" => "leg-1", "side" => "sell", "type" => "limit"},
          %{"id" => "leg-2", "side" => "sell", "type" => "stop"}
        ]
      }

      order = Order.from_map(data)

      assert length(order.legs) == 2
      assert Enum.at(order.legs, 0).id == "leg-1"
      assert Enum.at(order.legs, 1).id == "leg-2"
    end
  end
end
