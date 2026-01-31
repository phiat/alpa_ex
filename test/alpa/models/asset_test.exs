defmodule Alpa.Models.AssetTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Asset

  describe "from_map/1" do
    test "parses complete asset data" do
      data = %{
        "id" => "asset-123",
        "class" => "us_equity",
        "exchange" => "NASDAQ",
        "symbol" => "AAPL",
        "name" => "Apple Inc.",
        "status" => "active",
        "tradable" => true,
        "marginable" => true,
        "maintenance_margin_requirement" => "25",
        "shortable" => true,
        "easy_to_borrow" => true,
        "fractionable" => true,
        "min_order_size" => "1",
        "min_trade_increment" => "0.0001",
        "price_increment" => "0.01"
      }

      asset = Asset.from_map(data)

      assert asset.id == "asset-123"
      assert asset.class == :us_equity
      assert asset.exchange == "NASDAQ"
      assert asset.symbol == "AAPL"
      assert asset.name == "Apple Inc."
      assert asset.status == :active
      assert asset.tradable == true
      assert asset.marginable == true
      assert Decimal.eq?(asset.maintenance_margin_requirement, Decimal.new("25"))
      assert asset.shortable == true
      assert asset.easy_to_borrow == true
      assert asset.fractionable == true
      assert Decimal.eq?(asset.min_order_size, Decimal.new("1"))
    end

    test "parses crypto asset class" do
      asset = Asset.from_map(%{"class" => "crypto"})
      assert asset.class == :crypto
    end

    test "parses us_equity asset class" do
      asset = Asset.from_map(%{"class" => "us_equity"})
      assert asset.class == :us_equity
    end

    test "handles unknown asset class" do
      asset = Asset.from_map(%{"class" => "options"})
      assert asset.class == nil
    end

    test "parses active status" do
      asset = Asset.from_map(%{"status" => "active"})
      assert asset.status == :active
    end

    test "parses inactive status" do
      asset = Asset.from_map(%{"status" => "inactive"})
      assert asset.status == :inactive
    end

    test "handles unknown status" do
      asset = Asset.from_map(%{"status" => "delisted"})
      assert asset.status == nil
    end

    test "handles nil values" do
      asset = Asset.from_map(%{})

      assert asset.id == nil
      assert asset.class == nil
      assert asset.symbol == nil
      assert asset.status == nil
      assert asset.tradable == nil
    end

    test "parses integer decimal values" do
      asset = Asset.from_map(%{"maintenance_margin_requirement" => 25})
      assert Decimal.eq?(asset.maintenance_margin_requirement, Decimal.new(25))
    end

    test "parses float decimal values" do
      asset = Asset.from_map(%{"min_trade_increment" => 0.0001})
      assert asset.min_trade_increment != nil
    end

    test "handles boolean fields" do
      asset =
        Asset.from_map(%{
          "tradable" => false,
          "marginable" => false,
          "shortable" => false,
          "easy_to_borrow" => false,
          "fractionable" => false
        })

      assert asset.tradable == false
      assert asset.marginable == false
      assert asset.shortable == false
      assert asset.easy_to_borrow == false
      assert asset.fractionable == false
    end
  end
end
