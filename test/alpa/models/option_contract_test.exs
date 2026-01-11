defmodule Alpa.Models.OptionContractTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.OptionContract

  describe "from_map/1" do
    test "parses complete option contract data" do
      data = %{
        "id" => "contract-123",
        "symbol" => "AAPL240119C00190000",
        "name" => "AAPL Jan 19 2024 190 Call",
        "status" => "active",
        "tradable" => true,
        "expiration_date" => "2024-01-19",
        "strike_price" => "190.00",
        "type" => "call",
        "style" => "american",
        "root_symbol" => "AAPL",
        "underlying_symbol" => "AAPL",
        "underlying_asset_id" => "asset-456",
        "open_interest" => 5000,
        "open_interest_date" => "2024-01-15",
        "close_price" => "5.50",
        "close_price_date" => "2024-01-15"
      }

      contract = OptionContract.from_map(data)

      assert contract.id == "contract-123"
      assert contract.symbol == "AAPL240119C00190000"
      assert contract.name == "AAPL Jan 19 2024 190 Call"
      assert contract.status == "active"
      assert contract.tradable == true
      assert contract.expiration_date == ~D[2024-01-19]
      assert Decimal.eq?(contract.strike_price, Decimal.new("190.00"))
      assert contract.type == :call
      assert contract.style == :american
      assert contract.root_symbol == "AAPL"
      assert contract.underlying_symbol == "AAPL"
      assert contract.open_interest == 5000
      assert contract.open_interest_date == ~D[2024-01-15]
      assert Decimal.eq?(contract.close_price, Decimal.new("5.50"))
      assert contract.close_price_date == ~D[2024-01-15]
    end

    test "parses call type" do
      contract = OptionContract.from_map(%{"type" => "call"})
      assert contract.type == :call
    end

    test "parses put type" do
      contract = OptionContract.from_map(%{"type" => "put"})
      assert contract.type == :put
    end

    test "handles unknown type" do
      contract = OptionContract.from_map(%{"type" => "spread"})
      assert contract.type == nil
    end

    test "parses american style" do
      contract = OptionContract.from_map(%{"style" => "american"})
      assert contract.style == :american
    end

    test "parses european style" do
      contract = OptionContract.from_map(%{"style" => "european"})
      assert contract.style == :european
    end

    test "handles unknown style" do
      contract = OptionContract.from_map(%{"style" => "bermudan"})
      assert contract.style == nil
    end

    test "handles nil values" do
      contract = OptionContract.from_map(%{})

      assert contract.id == nil
      assert contract.symbol == nil
      assert contract.expiration_date == nil
      assert contract.strike_price == nil
      assert contract.type == nil
      assert contract.style == nil
    end

    test "handles invalid date" do
      contract = OptionContract.from_map(%{
        "expiration_date" => "not-a-date",
        "open_interest_date" => "invalid",
        "close_price_date" => ""
      })

      assert contract.expiration_date == nil
      assert contract.open_interest_date == nil
      assert contract.close_price_date == nil
    end

    test "parses integer strike price" do
      contract = OptionContract.from_map(%{"strike_price" => 190})
      assert Decimal.eq?(contract.strike_price, Decimal.new(190))
    end

    test "parses float strike price" do
      contract = OptionContract.from_map(%{"strike_price" => 190.50})
      assert contract.strike_price != nil
    end

    test "parses zero open interest" do
      contract = OptionContract.from_map(%{"open_interest" => 0})
      assert contract.open_interest == 0
    end
  end
end
