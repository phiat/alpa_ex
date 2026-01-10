defmodule Alpa.Models.QuoteTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Quote

  describe "from_map/2" do
    test "parses quote data" do
      data = %{
        "t" => "2024-01-15T10:30:00Z",
        "ap" => "150.10",
        "as" => 100,
        "ax" => "Q",
        "bp" => "150.00",
        "bs" => 200,
        "bx" => "P",
        "c" => ["R"],
        "z" => "A"
      }

      quote = Quote.from_map(data, "AAPL")

      assert quote.symbol == "AAPL"
      assert quote.timestamp == ~U[2024-01-15 10:30:00Z]
      assert Decimal.eq?(quote.ask_price, Decimal.new("150.10"))
      assert quote.ask_size == 100
      assert quote.ask_exchange == "Q"
      assert Decimal.eq?(quote.bid_price, Decimal.new("150.00"))
      assert quote.bid_size == 200
      assert quote.bid_exchange == "P"
      assert quote.conditions == ["R"]
      assert quote.tape == "A"
    end
  end

  describe "from_response/1" do
    test "parses multi-symbol response" do
      response = %{
        "quotes" => %{
          "AAPL" => [%{"t" => "2024-01-15T10:30:00Z", "bp" => "150.00"}],
          "MSFT" => [%{"t" => "2024-01-15T10:30:00Z", "bp" => "400.00"}]
        }
      }

      result = Quote.from_response(response)

      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")
    end
  end
end
