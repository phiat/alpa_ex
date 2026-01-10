defmodule Alpa.Models.BarTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Bar

  describe "from_map/2" do
    test "parses bar data with symbol" do
      data = %{
        "t" => "2024-01-15T10:30:00Z",
        "o" => "150.00",
        "h" => "152.50",
        "l" => "149.00",
        "c" => "151.75",
        "v" => 1_000_000,
        "n" => 5000,
        "vw" => "150.50"
      }

      bar = Bar.from_map(data, "AAPL")

      assert bar.symbol == "AAPL"
      assert bar.timestamp == ~U[2024-01-15 10:30:00Z]
      assert Decimal.eq?(bar.open, Decimal.new("150.00"))
      assert Decimal.eq?(bar.high, Decimal.new("152.50"))
      assert Decimal.eq?(bar.low, Decimal.new("149.00"))
      assert Decimal.eq?(bar.close, Decimal.new("151.75"))
      assert bar.volume == 1_000_000
      assert bar.trade_count == 5000
      assert Decimal.eq?(bar.vwap, Decimal.new("150.50"))
    end

    test "parses symbol from data if not provided" do
      data = %{
        "S" => "MSFT",
        "t" => "2024-01-15T10:30:00Z",
        "c" => "400.00"
      }

      bar = Bar.from_map(data)

      assert bar.symbol == "MSFT"
    end
  end

  describe "from_response/1" do
    test "parses multi-symbol response" do
      response = %{
        "bars" => %{
          "AAPL" => [
            %{"t" => "2024-01-15T10:30:00Z", "c" => "150.00"},
            %{"t" => "2024-01-16T10:30:00Z", "c" => "151.00"}
          ],
          "MSFT" => [
            %{"t" => "2024-01-15T10:30:00Z", "c" => "400.00"}
          ]
        }
      }

      result = Bar.from_response(response)

      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")
      assert length(result["AAPL"]) == 2
      assert length(result["MSFT"]) == 1
    end

    test "handles nil bars" do
      assert Bar.from_response(%{"bars" => nil}) == %{}
    end
  end
end
