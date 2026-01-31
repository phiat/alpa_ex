defmodule Alpa.Models.SnapshotTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Snapshot

  describe "from_map/2" do
    test "parses complete snapshot data" do
      data = %{
        "latestTrade" => %{
          "p" => 185.50,
          "s" => 100,
          "t" => "2024-01-15T10:30:00Z"
        },
        "latestQuote" => %{
          "bp" => 185.49,
          "ap" => 185.51,
          "bs" => 200,
          "as" => 300
        },
        "minuteBar" => %{
          "o" => 185.00,
          "h" => 186.00,
          "l" => 184.50,
          "c" => 185.50,
          "v" => 10000
        },
        "dailyBar" => %{
          "o" => 184.00,
          "h" => 187.00,
          "l" => 183.00,
          "c" => 185.50,
          "v" => 1_000_000
        },
        "prevDailyBar" => %{
          "o" => 183.00,
          "h" => 185.00,
          "l" => 182.00,
          "c" => 184.00,
          "v" => 900_000
        }
      }

      snapshot = Snapshot.from_map(data, "AAPL")

      assert snapshot.symbol == "AAPL"
      assert snapshot.latest_trade != nil
      assert snapshot.latest_trade.symbol == "AAPL"
      assert Decimal.eq?(snapshot.latest_trade.price, Decimal.from_float(185.50))
      assert snapshot.latest_quote != nil
      assert snapshot.latest_quote.symbol == "AAPL"
      assert snapshot.minute_bar != nil
      assert snapshot.daily_bar != nil
      assert snapshot.prev_daily_bar != nil
    end

    test "handles nil nested components" do
      snapshot = Snapshot.from_map(%{}, "AAPL")

      assert snapshot.symbol == "AAPL"
      assert snapshot.latest_trade == nil
      assert snapshot.latest_quote == nil
      assert snapshot.minute_bar == nil
      assert snapshot.daily_bar == nil
      assert snapshot.prev_daily_bar == nil
    end

    test "handles partial data" do
      data = %{
        "latestTrade" => %{"p" => 185.50},
        "latestQuote" => nil,
        "minuteBar" => %{"c" => 185.50}
      }

      snapshot = Snapshot.from_map(data, "AAPL")

      assert snapshot.latest_trade != nil
      assert snapshot.latest_quote == nil
      assert snapshot.minute_bar != nil
      assert snapshot.daily_bar == nil
    end

    test "propagates symbol to nested components" do
      data = %{
        "latestTrade" => %{"p" => 185.50},
        "latestQuote" => %{"bp" => 185.49},
        "minuteBar" => %{"c" => 185.50}
      }

      snapshot = Snapshot.from_map(data, "MSFT")

      assert snapshot.latest_trade.symbol == "MSFT"
      assert snapshot.latest_quote.symbol == "MSFT"
      assert snapshot.minute_bar.symbol == "MSFT"
    end
  end

  describe "from_response/1" do
    test "parses multi-symbol snapshots response" do
      data = %{
        "snapshots" => %{
          "AAPL" => %{
            "latestTrade" => %{"p" => 185.50}
          },
          "MSFT" => %{
            "latestTrade" => %{"p" => 380.00}
          }
        }
      }

      result = Snapshot.from_response(data)

      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")
      assert result["AAPL"].symbol == "AAPL"
      assert result["MSFT"].symbol == "MSFT"
    end

    test "returns data unchanged for unexpected format" do
      data = %{"unexpected" => "format"}
      assert Snapshot.from_response(data) == data
    end

    test "handles empty snapshots map" do
      data = %{"snapshots" => %{}}
      assert Snapshot.from_response(data) == %{}
    end
  end
end
