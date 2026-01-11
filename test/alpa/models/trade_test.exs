defmodule Alpa.Models.TradeTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Trade

  describe "from_map/2" do
    test "parses complete trade data" do
      data = %{
        "S" => "AAPL",
        "t" => "2024-01-15T10:30:00.123456Z",
        "p" => 185.50,
        "s" => 100,
        "x" => "V",
        "i" => 12345,
        "c" => ["@", "F"],
        "z" => "A"
      }

      trade = Trade.from_map(data)

      assert trade.symbol == "AAPL"
      assert trade.timestamp == ~U[2024-01-15 10:30:00.123456Z]
      assert Decimal.eq?(trade.price, Decimal.from_float(185.50))
      assert trade.size == 100
      assert trade.exchange == "V"
      assert trade.id == 12345
      assert trade.conditions == ["@", "F"]
      assert trade.tape == "A"
    end

    test "uses provided symbol over data symbol" do
      data = %{"S" => "MSFT", "p" => 100}
      trade = Trade.from_map(data, "AAPL")
      assert trade.symbol == "AAPL"
    end

    test "falls back to data symbol when none provided" do
      data = %{"S" => "GOOGL", "p" => 100}
      trade = Trade.from_map(data)
      assert trade.symbol == "GOOGL"
    end

    test "handles nil values" do
      trade = Trade.from_map(%{})

      assert trade.symbol == nil
      assert trade.timestamp == nil
      assert trade.price == nil
      assert trade.size == nil
      assert trade.exchange == nil
    end

    test "parses string price" do
      trade = Trade.from_map(%{"p" => "185.50"})
      assert Decimal.eq?(trade.price, Decimal.new("185.50"))
    end

    test "parses integer price" do
      trade = Trade.from_map(%{"p" => 100})
      assert Decimal.eq?(trade.price, Decimal.new(100))
    end

    test "parses float price with precision" do
      trade = Trade.from_map(%{"p" => 185.123456})
      assert trade.price != nil
    end

    test "handles invalid datetime gracefully" do
      trade = Trade.from_map(%{"t" => "not-a-date"})
      assert trade.timestamp == nil
    end

    test "handles empty string datetime" do
      trade = Trade.from_map(%{"t" => ""})
      assert trade.timestamp == nil
    end
  end

  describe "from_response/1" do
    test "parses multi-symbol response" do
      data = %{
        "trades" => %{
          "AAPL" => [
            %{"p" => 185.50, "s" => 100},
            %{"p" => 185.51, "s" => 50}
          ],
          "MSFT" => [
            %{"p" => 380.00, "s" => 200}
          ]
        }
      }

      result = Trade.from_response(data)

      assert is_map(result)
      assert length(result["AAPL"]) == 2
      assert length(result["MSFT"]) == 1
      assert hd(result["AAPL"]).symbol == "AAPL"
      assert hd(result["MSFT"]).symbol == "MSFT"
    end

    test "parses single-symbol list response" do
      data = %{
        "trades" => [
          %{"S" => "AAPL", "p" => 185.50},
          %{"S" => "AAPL", "p" => 185.51}
        ]
      }

      result = Trade.from_response(data)

      assert is_list(result)
      assert length(result) == 2
    end

    test "returns data unchanged for unexpected format" do
      data = %{"unexpected" => "format"}
      assert Trade.from_response(data) == data
    end

    test "handles empty trades list" do
      data = %{"trades" => []}
      assert Trade.from_response(data) == []
    end

    test "handles empty trades map" do
      data = %{"trades" => %{}}
      assert Trade.from_response(data) == %{}
    end
  end
end
