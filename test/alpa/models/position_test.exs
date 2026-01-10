defmodule Alpa.Models.PositionTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Position

  describe "from_map/1" do
    test "parses position data" do
      data = %{
        "asset_id" => "asset-123",
        "symbol" => "AAPL",
        "exchange" => "NASDAQ",
        "asset_class" => "us_equity",
        "qty" => "100",
        "avg_entry_price" => "150.00",
        "side" => "long",
        "market_value" => "15500.00",
        "cost_basis" => "15000.00",
        "unrealized_pl" => "500.00",
        "unrealized_plpc" => "0.0333",
        "current_price" => "155.00",
        "lastday_price" => "152.00",
        "change_today" => "0.0197"
      }

      position = Position.from_map(data)

      assert position.symbol == "AAPL"
      assert position.exchange == "NASDAQ"
      assert Decimal.eq?(position.qty, Decimal.new("100"))
      assert Decimal.eq?(position.avg_entry_price, Decimal.new("150.00"))
      assert position.side == :long
      assert Decimal.eq?(position.unrealized_pl, Decimal.new("500.00"))
    end

    test "parses side correctly" do
      assert Position.from_map(%{"side" => "long"}).side == :long
      assert Position.from_map(%{"side" => "short"}).side == :short
    end
  end
end
