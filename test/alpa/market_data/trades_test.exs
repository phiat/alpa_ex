defmodule Alpa.MarketData.TradesTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Trade
  alias Alpa.Test.MockClient
  alias Alpa.MarketData.Trades

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  # ── get/2 ──────────────────────────────────────────────────────────────

  describe "get/2" do
    test "requires credentials" do
      result = Trades.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed trades for a symbol" do
      trade_data = %{
        "trades" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "p" => "185.25",
            "s" => 100,
            "x" => "V",
            "i" => 12345,
            "c" => ["@", "T"],
            "z" => "A"
          },
          %{
            "t" => "2024-01-15T14:30:01Z",
            "p" => "185.30",
            "s" => 50,
            "x" => "Q",
            "i" => 12346,
            "c" => ["@"],
            "z" => "A"
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, trade_data})

      assert {:ok, trades} = Trades.get("AAPL")
      assert length(trades) == 2

      [first, second] = trades

      assert %Trade{} = first
      assert first.symbol == "AAPL"
      assert first.timestamp == ~U[2024-01-15 14:30:00Z]
      assert first.price == Decimal.new("185.25")
      assert first.size == 100
      assert first.exchange == "V"
      assert first.id == 12345
      assert first.conditions == ["@", "T"]
      assert first.tape == "A"

      assert %Trade{} = second
      assert second.symbol == "AAPL"
      assert second.timestamp == ~U[2024-01-15 14:30:01Z]
      assert second.price == Decimal.new("185.30")
      assert second.size == 50
      assert second.exchange == "Q"
      assert second.id == 12346
      assert second.conditions == ["@"]
      assert second.tape == "A"
    end

    test "handles symbol with special characters (URL encoding)" do
      trade_data = %{
        "trades" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "p" => "10.50",
            "s" => 200,
            "x" => "V",
            "i" => 99,
            "c" => [],
            "z" => "B"
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/BRK%2FB/trades", {:ok, trade_data})

      assert {:ok, [trade]} = Trades.get("BRK/B")
      assert trade.symbol == "BRK/B"
      assert trade.price == Decimal.new("10.50")
    end

    test "returns empty list when trades is nil" do
      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, %{"trades" => nil}})

      assert {:ok, []} = Trades.get("AAPL")
    end

    test "returns empty list when trades key is missing" do
      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, %{}})

      assert {:ok, []} = Trades.get("AAPL")
    end

    test "returns empty list when response is unexpected shape" do
      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, %{"something_else" => true}})

      assert {:ok, []} = Trades.get("AAPL")
    end

    test "propagates error from client" do
      error = %Error{type: :unauthorized, message: "Unauthorized", code: 401, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:error, error})

      assert {:error, %Error{type: :unauthorized}} = Trades.get("AAPL")
    end

    test "handles trade with update field" do
      trade_data = %{
        "trades" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "p" => "185.25",
            "s" => 100,
            "x" => "V",
            "i" => 12345,
            "c" => ["@"],
            "z" => "A",
            "u" => "corrected"
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, trade_data})

      assert {:ok, [trade]} = Trades.get("AAPL")
      assert trade.update == "corrected"
    end

    test "handles trade with nil/missing optional fields" do
      trade_data = %{
        "trades" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "p" => "185.25",
            "s" => 100,
            "x" => "V",
            "i" => nil,
            "c" => nil,
            "z" => nil
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/trades", {:ok, trade_data})

      assert {:ok, [trade]} = Trades.get("AAPL")
      assert trade.symbol == "AAPL"
      assert trade.id == nil
      assert trade.conditions == nil
      assert trade.tape == nil
      assert trade.update == nil
    end
  end

  # ── get_multi/2 ────────────────────────────────────────────────────────

  describe "get_multi/2" do
    test "requires credentials" do
      result = Trades.get_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed trades for multiple symbols" do
      multi_data = %{
        "trades" => %{
          "AAPL" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "p" => "185.25",
              "s" => 100,
              "x" => "V",
              "i" => 12345,
              "c" => ["@"],
              "z" => "A"
            }
          ],
          "MSFT" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "p" => "390.50",
              "s" => 75,
              "x" => "Q",
              "i" => 67890,
              "c" => ["@", "T"],
              "z" => "C"
            },
            %{
              "t" => "2024-01-15T14:30:02Z",
              "p" => "390.55",
              "s" => 25,
              "x" => "V",
              "i" => 67891,
              "c" => [],
              "z" => "C"
            }
          ]
        }
      }

      MockClient.mock_get_data("/v2/stocks/trades", {:ok, multi_data})

      assert {:ok, result} = Trades.get_multi(["AAPL", "MSFT"])
      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")

      assert [aapl_trade] = result["AAPL"]
      assert %Trade{} = aapl_trade
      assert aapl_trade.symbol == "AAPL"
      assert aapl_trade.price == Decimal.new("185.25")
      assert aapl_trade.size == 100
      assert aapl_trade.exchange == "V"

      assert [msft_trade_1, msft_trade_2] = result["MSFT"]
      assert msft_trade_1.symbol == "MSFT"
      assert msft_trade_1.price == Decimal.new("390.50")
      assert msft_trade_1.conditions == ["@", "T"]

      assert msft_trade_2.symbol == "MSFT"
      assert msft_trade_2.price == Decimal.new("390.55")
      assert msft_trade_2.size == 25
    end

    test "returns empty map when trades is nil" do
      MockClient.mock_get_data("/v2/stocks/trades", {:ok, %{"trades" => nil}})

      assert {:ok, %{}} = Trades.get_multi(["AAPL"])
    end

    test "returns empty map when trades key is missing" do
      MockClient.mock_get_data("/v2/stocks/trades", {:ok, %{}})

      assert {:ok, %{}} = Trades.get_multi(["AAPL"])
    end

    test "propagates error from client" do
      error = %Error{type: :rate_limited, message: "Too many requests", code: 429, details: nil}
      MockClient.mock_get_data("/v2/stocks/trades", {:error, error})

      assert {:error, %Error{type: :rate_limited}} = Trades.get_multi(["AAPL", "MSFT"])
    end
  end

  # ── latest/2 ───────────────────────────────────────────────────────────

  describe "latest/2" do
    test "requires credentials" do
      result = Trades.latest("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single parsed trade" do
      latest_data = %{
        "trade" => %{
          "t" => "2024-01-15T20:00:00Z",
          "p" => "186.00",
          "s" => 500,
          "x" => "V",
          "i" => 99999,
          "c" => ["@"],
          "z" => "A"
        }
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/trades/latest", {:ok, latest_data})

      assert {:ok, trade} = Trades.latest("AAPL")
      assert %Trade{} = trade
      assert trade.symbol == "AAPL"
      assert trade.timestamp == ~U[2024-01-15 20:00:00Z]
      assert trade.price == Decimal.new("186.00")
      assert trade.size == 500
      assert trade.exchange == "V"
      assert trade.id == 99999
      assert trade.conditions == ["@"]
      assert trade.tape == "A"
    end

    test "handles symbol with special characters (URL encoding)" do
      latest_data = %{
        "trade" => %{
          "t" => "2024-01-15T20:00:00Z",
          "p" => "420.00",
          "s" => 10,
          "x" => "Q",
          "i" => 55555,
          "c" => [],
          "z" => "B"
        }
      }

      MockClient.mock_get_data("/v2/stocks/BRK%2FB/trades/latest", {:ok, latest_data})

      assert {:ok, trade} = Trades.latest("BRK/B")
      assert trade.symbol == "BRK/B"
      assert trade.price == Decimal.new("420.00")
    end

    test "returns invalid_response error when trade key is missing" do
      MockClient.mock_get_data(
        "/v2/stocks/AAPL/trades/latest",
        {:ok, %{"something" => "unexpected"}}
      )

      assert {:error, %Error{type: :invalid_response}} = Trades.latest("AAPL")
    end

    test "returns invalid_response error when response is empty map" do
      MockClient.mock_get_data("/v2/stocks/AAPL/trades/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Trades.latest("AAPL")
    end

    test "raises when trade value is nil (unhandled edge case)" do
      MockClient.mock_get_data(
        "/v2/stocks/AAPL/trades/latest",
        {:ok, %{"trade" => nil}}
      )

      # %{"trade" => trade} pattern matches with trade = nil,
      # then Trade.from_map(nil, symbol) raises because of the
      # `when is_map(data)` guard on from_map/2.
      assert_raise FunctionClauseError, fn ->
        Trades.latest("AAPL")
      end
    end

    test "propagates error from client" do
      error = %Error{type: :not_found, message: "Not found", code: 404, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/trades/latest", {:error, error})

      assert {:error, %Error{type: :not_found}} = Trades.latest("AAPL")
    end

    test "returns trade with update field" do
      latest_data = %{
        "trade" => %{
          "t" => "2024-01-15T20:00:00Z",
          "p" => "186.00",
          "s" => 500,
          "x" => "V",
          "i" => 99999,
          "c" => ["@"],
          "z" => "A",
          "u" => "canceled"
        }
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/trades/latest", {:ok, latest_data})

      assert {:ok, trade} = Trades.latest("AAPL")
      assert trade.update == "canceled"
    end
  end

  # ── latest_multi/2 ─────────────────────────────────────────────────────

  describe "latest_multi/2" do
    test "requires credentials" do
      result = Trades.latest_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed trades for multiple symbols" do
      latest_multi_data = %{
        "trades" => %{
          "AAPL" => %{
            "t" => "2024-01-15T20:00:00Z",
            "p" => "186.00",
            "s" => 500,
            "x" => "V",
            "i" => 99999,
            "c" => ["@"],
            "z" => "A"
          },
          "MSFT" => %{
            "t" => "2024-01-15T20:00:00Z",
            "p" => "391.75",
            "s" => 200,
            "x" => "Q",
            "i" => 88888,
            "c" => ["@", "T"],
            "z" => "C"
          }
        }
      }

      MockClient.mock_get_data("/v2/stocks/trades/latest", {:ok, latest_multi_data})

      assert {:ok, result} = Trades.latest_multi(["AAPL", "MSFT"])
      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")

      aapl = result["AAPL"]
      assert %Trade{} = aapl
      assert aapl.symbol == "AAPL"
      assert aapl.timestamp == ~U[2024-01-15 20:00:00Z]
      assert aapl.price == Decimal.new("186.00")
      assert aapl.size == 500
      assert aapl.exchange == "V"
      assert aapl.id == 99999
      assert aapl.conditions == ["@"]
      assert aapl.tape == "A"

      msft = result["MSFT"]
      assert %Trade{} = msft
      assert msft.symbol == "MSFT"
      assert msft.timestamp == ~U[2024-01-15 20:00:00Z]
      assert msft.price == Decimal.new("391.75")
      assert msft.size == 200
      assert msft.exchange == "Q"
      assert msft.id == 88888
      assert msft.conditions == ["@", "T"]
      assert msft.tape == "C"
    end

    test "returns invalid_response error when trades key is missing" do
      MockClient.mock_get_data(
        "/v2/stocks/trades/latest",
        {:ok, %{"unexpected" => "data"}}
      )

      assert {:error, %Error{type: :invalid_response}} = Trades.latest_multi(["AAPL"])
    end

    test "returns invalid_response error when response is empty map" do
      MockClient.mock_get_data("/v2/stocks/trades/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Trades.latest_multi(["AAPL"])
    end

    test "propagates error from client" do
      error = %Error{
        type: :server_error,
        message: "Internal server error",
        code: 500,
        details: nil
      }

      MockClient.mock_get_data("/v2/stocks/trades/latest", {:error, error})

      assert {:error, %Error{type: :server_error}} = Trades.latest_multi(["AAPL", "MSFT"])
    end

    test "handles single symbol in list" do
      latest_multi_data = %{
        "trades" => %{
          "AAPL" => %{
            "t" => "2024-01-15T20:00:00Z",
            "p" => "186.00",
            "s" => 500,
            "x" => "V",
            "i" => 99999,
            "c" => ["@"],
            "z" => "A"
          }
        }
      }

      MockClient.mock_get_data("/v2/stocks/trades/latest", {:ok, latest_multi_data})

      assert {:ok, result} = Trades.latest_multi(["AAPL"])
      assert map_size(result) == 1
      assert %Trade{symbol: "AAPL"} = result["AAPL"]
    end
  end
end
