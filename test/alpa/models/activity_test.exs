defmodule Alpa.Models.ActivityTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Activity

  describe "from_map/1" do
    test "parses trade activity data" do
      data = %{
        "id" => "20240115000000000::abc123",
        "activity_type" => "FILL",
        "date" => "2024-01-15",
        "net_amount" => "-1855.00",
        "symbol" => "AAPL",
        "qty" => "10",
        "per_share_amount" => "185.50",
        "price" => "185.50",
        "cum_qty" => "10",
        "leaves_qty" => "0",
        "side" => "buy",
        "type" => "fill",
        "order_id" => "order-abc-123",
        "transaction_time" => "2024-01-15T10:30:00.123456Z",
        "description" => "10 shares of AAPL bought",
        "status" => "executed"
      }

      activity = Activity.from_map(data)

      assert activity.id == "20240115000000000::abc123"
      assert activity.activity_type == "FILL"
      assert activity.date == ~D[2024-01-15]
      assert Decimal.eq?(activity.net_amount, Decimal.new("-1855.00"))
      assert activity.symbol == "AAPL"
      assert Decimal.eq?(activity.qty, Decimal.new("10"))
      assert Decimal.eq?(activity.per_share_amount, Decimal.new("185.50"))
      assert Decimal.eq?(activity.price, Decimal.new("185.50"))
      assert Decimal.eq?(activity.cum_qty, Decimal.new("10"))
      assert Decimal.eq?(activity.leaves_qty, Decimal.new("0"))
      assert activity.side == "buy"
      assert activity.type == "fill"
      assert activity.order_id == "order-abc-123"
      assert activity.transaction_time.year == 2024
      assert activity.transaction_time.month == 1
      assert activity.description == "10 shares of AAPL bought"
      assert activity.status == "executed"
    end

    test "parses dividend activity data" do
      data = %{
        "id" => "20240215000000000::div456",
        "activity_type" => "DIV",
        "date" => "2024-02-15",
        "net_amount" => "24.00",
        "symbol" => "AAPL",
        "per_share_amount" => "0.24",
        "qty" => "100",
        "description" => "Dividend payment",
        "status" => "executed"
      }

      activity = Activity.from_map(data)

      assert activity.activity_type == "DIV"
      assert Decimal.eq?(activity.net_amount, Decimal.new("24.00"))
      assert Decimal.eq?(activity.per_share_amount, Decimal.new("0.24"))
    end

    test "handles nil values" do
      activity = Activity.from_map(%{})

      assert activity.id == nil
      assert activity.activity_type == nil
      assert activity.date == nil
      assert activity.net_amount == nil
      assert activity.symbol == nil
      assert activity.qty == nil
      assert activity.per_share_amount == nil
      assert activity.price == nil
      assert activity.transaction_time == nil
    end

    test "handles invalid date" do
      activity = Activity.from_map(%{"date" => "not-a-date"})
      assert activity.date == nil
    end

    test "handles invalid datetime" do
      activity = Activity.from_map(%{"transaction_time" => "not-a-datetime"})
      assert activity.transaction_time == nil
    end
  end
end
