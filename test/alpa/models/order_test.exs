defmodule Alpa.Models.OrderTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Order

  describe "from_map/1" do
    test "parses complete order data" do
      data = %{
        "id" => "order-123",
        "client_order_id" => "client-456",
        "created_at" => "2024-01-15T10:30:00.123456Z",
        "updated_at" => "2024-01-15T10:30:01.123456Z",
        "submitted_at" => "2024-01-15T10:30:00.123456Z",
        "filled_at" => "2024-01-15T10:30:02.123456Z",
        "asset_id" => "asset-789",
        "symbol" => "AAPL",
        "asset_class" => "us_equity",
        "qty" => "10",
        "filled_qty" => "10",
        "filled_avg_price" => "185.50",
        "order_class" => "simple",
        "order_type" => "limit",
        "type" => "limit",
        "side" => "buy",
        "time_in_force" => "gtc",
        "limit_price" => "185.00",
        "status" => "filled",
        "extended_hours" => true
      }

      order = Order.from_map(data)

      assert order.id == "order-123"
      assert order.client_order_id == "client-456"
      assert order.symbol == "AAPL"
      assert order.asset_class == "us_equity"
      assert Decimal.eq?(order.qty, Decimal.new("10"))
      assert Decimal.eq?(order.filled_qty, Decimal.new("10"))
      assert Decimal.eq?(order.filled_avg_price, Decimal.new("185.50"))
      assert order.order_class == :simple
      assert order.order_type == :limit
      assert order.type == "limit"
      assert order.side == :buy
      assert order.time_in_force == :gtc
      assert Decimal.eq?(order.limit_price, Decimal.new("185.00"))
      assert order.status == :filled
      assert order.extended_hours == true
      assert order.created_at.year == 2024
      assert order.filled_at != nil
    end

    test "handles nil values" do
      order = Order.from_map(%{})

      assert order.id == nil
      assert order.symbol == nil
      assert order.qty == nil
      assert order.side == nil
      assert order.order_type == nil
      assert order.status == nil
    end
  end

  describe "side parsing" do
    test "parses buy side" do
      order = Order.from_map(%{"side" => "buy"})
      assert order.side == :buy
    end

    test "parses sell side" do
      order = Order.from_map(%{"side" => "sell"})
      assert order.side == :sell
    end

    test "handles unknown side" do
      order = Order.from_map(%{"side" => "short"})
      assert order.side == nil
    end

    test "handles nil side" do
      order = Order.from_map(%{"side" => nil})
      assert order.side == nil
    end
  end

  describe "order type parsing" do
    test "parses market type" do
      order = Order.from_map(%{"order_type" => "market"})
      assert order.order_type == :market
    end

    test "parses limit type" do
      order = Order.from_map(%{"order_type" => "limit"})
      assert order.order_type == :limit
    end

    test "parses stop type" do
      order = Order.from_map(%{"order_type" => "stop"})
      assert order.order_type == :stop
    end

    test "parses stop_limit type" do
      order = Order.from_map(%{"order_type" => "stop_limit"})
      assert order.order_type == :stop_limit
    end

    test "parses trailing_stop type" do
      order = Order.from_map(%{"order_type" => "trailing_stop"})
      assert order.order_type == :trailing_stop
    end

    test "falls back to type field when order_type is nil" do
      order = Order.from_map(%{"type" => "limit"})
      assert order.order_type == :limit
    end

    test "handles unknown order type" do
      order = Order.from_map(%{"order_type" => "exotic"})
      assert order.order_type == nil
    end
  end

  describe "time in force parsing" do
    test "parses day" do
      order = Order.from_map(%{"time_in_force" => "day"})
      assert order.time_in_force == :day
    end

    test "parses gtc" do
      order = Order.from_map(%{"time_in_force" => "gtc"})
      assert order.time_in_force == :gtc
    end

    test "parses opg" do
      order = Order.from_map(%{"time_in_force" => "opg"})
      assert order.time_in_force == :opg
    end

    test "parses cls" do
      order = Order.from_map(%{"time_in_force" => "cls"})
      assert order.time_in_force == :cls
    end

    test "parses ioc" do
      order = Order.from_map(%{"time_in_force" => "ioc"})
      assert order.time_in_force == :ioc
    end

    test "parses fok" do
      order = Order.from_map(%{"time_in_force" => "fok"})
      assert order.time_in_force == :fok
    end

    test "handles unknown time in force" do
      order = Order.from_map(%{"time_in_force" => "custom"})
      assert order.time_in_force == nil
    end
  end

  describe "order class parsing" do
    test "parses simple order class" do
      order = Order.from_map(%{"order_class" => "simple"})
      assert order.order_class == :simple
    end

    test "parses bracket order class" do
      order = Order.from_map(%{"order_class" => "bracket"})
      assert order.order_class == :bracket
    end

    test "parses oco order class" do
      order = Order.from_map(%{"order_class" => "oco"})
      assert order.order_class == :oco
    end

    test "parses oto order class" do
      order = Order.from_map(%{"order_class" => "oto"})
      assert order.order_class == :oto
    end

    test "defaults empty string to simple" do
      order = Order.from_map(%{"order_class" => ""})
      assert order.order_class == :simple
    end

    test "defaults nil to simple" do
      order = Order.from_map(%{"order_class" => nil})
      assert order.order_class == :simple
    end

    test "defaults unknown to simple" do
      order = Order.from_map(%{"order_class" => "complex"})
      assert order.order_class == :simple
    end
  end

  describe "status parsing" do
    test "parses new status" do
      order = Order.from_map(%{"status" => "new"})
      assert order.status == :new
    end

    test "parses partially_filled status" do
      order = Order.from_map(%{"status" => "partially_filled"})
      assert order.status == :partially_filled
    end

    test "parses filled status" do
      order = Order.from_map(%{"status" => "filled"})
      assert order.status == :filled
    end

    test "parses done_for_day status" do
      order = Order.from_map(%{"status" => "done_for_day"})
      assert order.status == :done_for_day
    end

    test "parses canceled status" do
      order = Order.from_map(%{"status" => "canceled"})
      assert order.status == :canceled
    end

    test "parses expired status" do
      order = Order.from_map(%{"status" => "expired"})
      assert order.status == :expired
    end

    test "parses replaced status" do
      order = Order.from_map(%{"status" => "replaced"})
      assert order.status == :replaced
    end

    test "parses pending_cancel status" do
      order = Order.from_map(%{"status" => "pending_cancel"})
      assert order.status == :pending_cancel
    end

    test "parses pending_replace status" do
      order = Order.from_map(%{"status" => "pending_replace"})
      assert order.status == :pending_replace
    end

    test "parses pending_new status" do
      order = Order.from_map(%{"status" => "pending_new"})
      assert order.status == :pending_new
    end

    test "parses accepted status" do
      order = Order.from_map(%{"status" => "accepted"})
      assert order.status == :accepted
    end

    test "parses rejected status" do
      order = Order.from_map(%{"status" => "rejected"})
      assert order.status == :rejected
    end

    test "parses held status" do
      order = Order.from_map(%{"status" => "held"})
      assert order.status == :held
    end

    test "handles nil status" do
      order = Order.from_map(%{"status" => nil})
      assert order.status == nil
    end

    test "handles unknown status" do
      import ExUnit.CaptureLog

      log =
        capture_log(fn ->
          order = Order.from_map(%{"status" => "unknown_status"})
          assert order.status == nil
        end)

      assert log =~ "Unknown order status"
    end
  end

  describe "decimal parsing" do
    test "parses string quantities" do
      order = Order.from_map(%{"qty" => "100"})
      assert Decimal.eq?(order.qty, Decimal.new("100"))
    end

    test "parses integer quantities" do
      order = Order.from_map(%{"qty" => 100})
      assert Decimal.eq?(order.qty, Decimal.new(100))
    end

    test "parses float prices" do
      order = Order.from_map(%{"limit_price" => 185.50})
      assert order.limit_price != nil
    end

    test "handles nil decimals" do
      order = Order.from_map(%{"qty" => nil, "limit_price" => nil})
      assert order.qty == nil
      assert order.limit_price == nil
    end

    test "parses notional amounts" do
      order = Order.from_map(%{"notional" => "5000.00"})
      assert Decimal.eq?(order.notional, Decimal.new("5000.00"))
    end

    test "parses trailing stop values" do
      order =
        Order.from_map(%{
          "trail_percent" => "1.5",
          "trail_price" => "5.00",
          "hwm" => "190.00"
        })

      assert Decimal.eq?(order.trail_percent, Decimal.new("1.5"))
      assert Decimal.eq?(order.trail_price, Decimal.new("5.00"))
      assert Decimal.eq?(order.hwm, Decimal.new("190.00"))
    end
  end

  describe "datetime parsing" do
    test "parses ISO8601 timestamps" do
      order = Order.from_map(%{"created_at" => "2024-01-15T10:30:00.123456Z"})
      assert order.created_at.year == 2024
      assert order.created_at.month == 1
      assert order.created_at.day == 15
    end

    test "handles nil timestamps" do
      order = Order.from_map(%{"created_at" => nil})
      assert order.created_at == nil
    end

    test "handles invalid timestamps" do
      order = Order.from_map(%{"created_at" => "not-a-date"})
      assert order.created_at == nil
    end

    test "parses all timestamp fields" do
      data = %{
        "expired_at" => "2024-01-15T16:00:00Z",
        "canceled_at" => "2024-01-15T14:00:00Z",
        "failed_at" => "2024-01-15T12:00:00Z",
        "replaced_at" => "2024-01-15T13:00:00Z"
      }

      order = Order.from_map(data)

      assert order.expired_at != nil
      assert order.canceled_at != nil
      assert order.failed_at != nil
      assert order.replaced_at != nil
    end
  end

  describe "nested legs parsing" do
    test "parses bracket order with legs" do
      data = %{
        "id" => "parent-order",
        "order_class" => "bracket",
        "legs" => [
          %{
            "id" => "take-profit-leg",
            "order_type" => "limit",
            "side" => "sell",
            "limit_price" => "200.00"
          },
          %{
            "id" => "stop-loss-leg",
            "order_type" => "stop",
            "side" => "sell",
            "stop_price" => "170.00"
          }
        ]
      }

      order = Order.from_map(data)

      assert order.order_class == :bracket
      assert length(order.legs) == 2
      [take_profit, stop_loss] = order.legs
      assert take_profit.id == "take-profit-leg"
      assert take_profit.order_type == :limit
      assert stop_loss.id == "stop-loss-leg"
      assert stop_loss.order_type == :stop
    end

    test "handles nil legs" do
      order = Order.from_map(%{"legs" => nil})
      assert order.legs == nil
    end

    test "handles empty legs" do
      order = Order.from_map(%{"legs" => []})
      assert order.legs == []
    end
  end

  describe "replaced order fields" do
    test "parses replacement chain fields" do
      data = %{
        "id" => "new-order",
        "replaced_by" => nil,
        "replaces" => "old-order"
      }

      order = Order.from_map(data)

      assert order.replaces == "old-order"
      assert order.replaced_by == nil
    end

    test "parses replaced_by when order was replaced" do
      data = %{
        "id" => "old-order",
        "status" => "replaced",
        "replaced_by" => "new-order"
      }

      order = Order.from_map(data)

      assert order.status == :replaced
      assert order.replaced_by == "new-order"
    end
  end
end
