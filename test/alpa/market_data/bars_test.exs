defmodule Alpa.MarketData.BarsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Bar
  alias Alpa.Test.MockClient
  alias Alpa.MarketData.Bars

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  # ── get/2 ──────────────────────────────────────────────────────────────

  describe "get/2" do
    test "requires credentials" do
      result = Bars.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed bars for a symbol" do
      bar_data = %{
        "bars" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "o" => "185.00",
            "h" => "186.50",
            "l" => "184.75",
            "c" => "186.00",
            "v" => 1_500_000,
            "n" => 12000,
            "vw" => "185.60"
          },
          %{
            "t" => "2024-01-16T14:30:00Z",
            "o" => "186.25",
            "h" => "187.00",
            "l" => "185.50",
            "c" => "186.80",
            "v" => 1_200_000,
            "n" => 9500,
            "vw" => "186.40"
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:ok, bar_data})

      assert {:ok, bars} = Bars.get("AAPL")
      assert length(bars) == 2

      [first, second] = bars

      assert %Bar{} = first
      assert first.symbol == "AAPL"
      assert first.timestamp == ~U[2024-01-15 14:30:00Z]
      assert Decimal.eq?(first.open, Decimal.new("185.00"))
      assert Decimal.eq?(first.high, Decimal.new("186.50"))
      assert Decimal.eq?(first.low, Decimal.new("184.75"))
      assert Decimal.eq?(first.close, Decimal.new("186.00"))
      assert first.volume == 1_500_000
      assert first.trade_count == 12000
      assert Decimal.eq?(first.vwap, Decimal.new("185.60"))

      assert %Bar{} = second
      assert second.symbol == "AAPL"
      assert second.timestamp == ~U[2024-01-16 14:30:00Z]
      assert Decimal.eq?(second.open, Decimal.new("186.25"))
      assert Decimal.eq?(second.high, Decimal.new("187.00"))
      assert Decimal.eq?(second.low, Decimal.new("185.50"))
      assert Decimal.eq?(second.close, Decimal.new("186.80"))
      assert second.volume == 1_200_000
      assert second.trade_count == 9500
      assert Decimal.eq?(second.vwap, Decimal.new("186.40"))
    end

    test "handles symbol with special characters (URL encoding)" do
      bar_data = %{
        "bars" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "o" => "420.00",
            "h" => "425.00",
            "l" => "418.00",
            "c" => "423.50",
            "v" => 50_000,
            "n" => 300,
            "vw" => "421.75"
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/BRK%2FB/bars", {:ok, bar_data})

      assert {:ok, [bar]} = Bars.get("BRK/B")
      assert bar.symbol == "BRK/B"
      assert Decimal.eq?(bar.open, Decimal.new("420.00"))
    end

    test "returns empty list when bars is nil" do
      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:ok, %{"bars" => nil}})

      assert {:ok, []} = Bars.get("AAPL")
    end

    test "returns empty list when bars key is missing" do
      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:ok, %{}})

      assert {:ok, []} = Bars.get("AAPL")
    end

    test "returns empty list when response is unexpected shape" do
      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:ok, %{"something_else" => true}})

      assert {:ok, []} = Bars.get("AAPL")
    end

    test "propagates error from client" do
      error = %Error{type: :unauthorized, message: "Unauthorized", code: 401, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:error, error})

      assert {:error, %Error{type: :unauthorized}} = Bars.get("AAPL")
    end

    test "handles bar with nil optional fields" do
      bar_data = %{
        "bars" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "o" => "185.00",
            "h" => "186.50",
            "l" => "184.75",
            "c" => "186.00",
            "v" => 1_500_000,
            "n" => nil,
            "vw" => nil
          }
        ]
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/bars", {:ok, bar_data})

      assert {:ok, [bar]} = Bars.get("AAPL")
      assert bar.symbol == "AAPL"
      assert bar.trade_count == nil
      assert bar.vwap == nil
    end
  end

  # ── get_multi/2 ────────────────────────────────────────────────────────

  describe "get_multi/2" do
    test "requires credentials" do
      result = Bars.get_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed bars for multiple symbols" do
      multi_data = %{
        "bars" => %{
          "AAPL" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "o" => "185.00",
              "h" => "186.50",
              "l" => "184.75",
              "c" => "186.00",
              "v" => 1_500_000,
              "n" => 12000,
              "vw" => "185.60"
            }
          ],
          "MSFT" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "o" => "390.00",
              "h" => "392.00",
              "l" => "389.00",
              "c" => "391.50",
              "v" => 800_000,
              "n" => 7000,
              "vw" => "390.80"
            },
            %{
              "t" => "2024-01-16T14:30:00Z",
              "o" => "391.75",
              "h" => "393.00",
              "l" => "390.50",
              "c" => "392.25",
              "v" => 650_000,
              "n" => 5500,
              "vw" => "391.90"
            }
          ]
        }
      }

      MockClient.mock_get_data("/v2/stocks/bars", {:ok, multi_data})

      assert {:ok, result} = Bars.get_multi(["AAPL", "MSFT"])
      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")

      assert [aapl_bar] = result["AAPL"]
      assert %Bar{} = aapl_bar
      assert aapl_bar.symbol == "AAPL"
      assert Decimal.eq?(aapl_bar.open, Decimal.new("185.00"))
      assert Decimal.eq?(aapl_bar.high, Decimal.new("186.50"))
      assert Decimal.eq?(aapl_bar.low, Decimal.new("184.75"))
      assert Decimal.eq?(aapl_bar.close, Decimal.new("186.00"))
      assert aapl_bar.volume == 1_500_000
      assert aapl_bar.trade_count == 12000
      assert Decimal.eq?(aapl_bar.vwap, Decimal.new("185.60"))

      assert [msft_bar_1, msft_bar_2] = result["MSFT"]
      assert msft_bar_1.symbol == "MSFT"
      assert Decimal.eq?(msft_bar_1.open, Decimal.new("390.00"))
      assert Decimal.eq?(msft_bar_1.close, Decimal.new("391.50"))
      assert msft_bar_1.volume == 800_000

      assert msft_bar_2.symbol == "MSFT"
      assert Decimal.eq?(msft_bar_2.open, Decimal.new("391.75"))
      assert Decimal.eq?(msft_bar_2.close, Decimal.new("392.25"))
      assert msft_bar_2.volume == 650_000
    end

    test "returns empty map when bars is nil" do
      MockClient.mock_get_data("/v2/stocks/bars", {:ok, %{"bars" => nil}})

      assert {:ok, %{}} = Bars.get_multi(["AAPL"])
    end

    test "returns empty map when bars key is missing" do
      MockClient.mock_get_data("/v2/stocks/bars", {:ok, %{}})

      assert {:ok, %{}} = Bars.get_multi(["AAPL"])
    end

    test "propagates error from client" do
      error = %Error{type: :rate_limited, message: "Too many requests", code: 429, details: nil}
      MockClient.mock_get_data("/v2/stocks/bars", {:error, error})

      assert {:error, %Error{type: :rate_limited}} = Bars.get_multi(["AAPL", "MSFT"])
    end
  end

  # ── latest/2 ───────────────────────────────────────────────────────────

  describe "latest/2" do
    test "requires credentials" do
      result = Bars.latest("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single parsed bar" do
      latest_data = %{
        "bar" => %{
          "t" => "2024-01-15T20:00:00Z",
          "o" => "185.50",
          "h" => "186.75",
          "l" => "185.00",
          "c" => "186.25",
          "v" => 2_000_000,
          "n" => 15000,
          "vw" => "185.90"
        }
      }

      MockClient.mock_get_data("/v2/stocks/AAPL/bars/latest", {:ok, latest_data})

      assert {:ok, bar} = Bars.latest("AAPL")
      assert %Bar{} = bar
      assert bar.symbol == "AAPL"
      assert bar.timestamp == ~U[2024-01-15 20:00:00Z]
      assert Decimal.eq?(bar.open, Decimal.new("185.50"))
      assert Decimal.eq?(bar.high, Decimal.new("186.75"))
      assert Decimal.eq?(bar.low, Decimal.new("185.00"))
      assert Decimal.eq?(bar.close, Decimal.new("186.25"))
      assert bar.volume == 2_000_000
      assert bar.trade_count == 15000
      assert Decimal.eq?(bar.vwap, Decimal.new("185.90"))
    end

    test "handles symbol with special characters (URL encoding)" do
      latest_data = %{
        "bar" => %{
          "t" => "2024-01-15T20:00:00Z",
          "o" => "420.00",
          "h" => "425.00",
          "l" => "418.00",
          "c" => "423.50",
          "v" => 50_000,
          "n" => 300,
          "vw" => "421.75"
        }
      }

      MockClient.mock_get_data("/v2/stocks/BRK%2FB/bars/latest", {:ok, latest_data})

      assert {:ok, bar} = Bars.latest("BRK/B")
      assert bar.symbol == "BRK/B"
      assert Decimal.eq?(bar.open, Decimal.new("420.00"))
    end

    test "returns invalid_response error when bar key is missing" do
      MockClient.mock_get_data(
        "/v2/stocks/AAPL/bars/latest",
        {:ok, %{"something" => "unexpected"}}
      )

      assert {:error, %Error{type: :invalid_response}} = Bars.latest("AAPL")
    end

    test "returns invalid_response error when response is empty map" do
      MockClient.mock_get_data("/v2/stocks/AAPL/bars/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Bars.latest("AAPL")
    end

    test "raises when bar value is nil" do
      MockClient.mock_get_data(
        "/v2/stocks/AAPL/bars/latest",
        {:ok, %{"bar" => nil}}
      )

      # %{"bar" => bar} pattern matches with bar = nil,
      # then Bar.from_map(nil, symbol) raises because of the
      # `when is_map(data)` guard on from_map/2.
      assert_raise FunctionClauseError, fn ->
        Bars.latest("AAPL")
      end
    end

    test "propagates error from client" do
      error = %Error{type: :not_found, message: "Not found", code: 404, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/bars/latest", {:error, error})

      assert {:error, %Error{type: :not_found}} = Bars.latest("AAPL")
    end
  end

  # ── latest_multi/2 ─────────────────────────────────────────────────────

  describe "latest_multi/2" do
    test "requires credentials" do
      result = Bars.latest_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed bars for multiple symbols" do
      latest_multi_data = %{
        "bars" => %{
          "AAPL" => %{
            "t" => "2024-01-15T20:00:00Z",
            "o" => "185.50",
            "h" => "186.75",
            "l" => "185.00",
            "c" => "186.25",
            "v" => 2_000_000,
            "n" => 15000,
            "vw" => "185.90"
          },
          "MSFT" => %{
            "t" => "2024-01-15T20:00:00Z",
            "o" => "391.00",
            "h" => "393.50",
            "l" => "390.00",
            "c" => "392.75",
            "v" => 1_100_000,
            "n" => 8500,
            "vw" => "391.80"
          }
        }
      }

      MockClient.mock_get_data("/v2/stocks/bars/latest", {:ok, latest_multi_data})

      assert {:ok, result} = Bars.latest_multi(["AAPL", "MSFT"])
      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")

      aapl = result["AAPL"]
      assert %Bar{} = aapl
      assert aapl.symbol == "AAPL"
      assert aapl.timestamp == ~U[2024-01-15 20:00:00Z]
      assert Decimal.eq?(aapl.open, Decimal.new("185.50"))
      assert Decimal.eq?(aapl.high, Decimal.new("186.75"))
      assert Decimal.eq?(aapl.low, Decimal.new("185.00"))
      assert Decimal.eq?(aapl.close, Decimal.new("186.25"))
      assert aapl.volume == 2_000_000
      assert aapl.trade_count == 15000
      assert Decimal.eq?(aapl.vwap, Decimal.new("185.90"))

      msft = result["MSFT"]
      assert %Bar{} = msft
      assert msft.symbol == "MSFT"
      assert msft.timestamp == ~U[2024-01-15 20:00:00Z]
      assert Decimal.eq?(msft.open, Decimal.new("391.00"))
      assert Decimal.eq?(msft.high, Decimal.new("393.50"))
      assert Decimal.eq?(msft.low, Decimal.new("390.00"))
      assert Decimal.eq?(msft.close, Decimal.new("392.75"))
      assert msft.volume == 1_100_000
      assert msft.trade_count == 8500
      assert Decimal.eq?(msft.vwap, Decimal.new("391.80"))
    end

    test "returns invalid_response error when bars key is missing" do
      MockClient.mock_get_data(
        "/v2/stocks/bars/latest",
        {:ok, %{"unexpected" => "data"}}
      )

      assert {:error, %Error{type: :invalid_response}} = Bars.latest_multi(["AAPL"])
    end

    test "returns invalid_response error when response is empty map" do
      MockClient.mock_get_data("/v2/stocks/bars/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Bars.latest_multi(["AAPL"])
    end

    test "propagates error from client" do
      error = %Error{type: :server_error, message: "Internal server error", code: 500, details: nil}
      MockClient.mock_get_data("/v2/stocks/bars/latest", {:error, error})

      assert {:error, %Error{type: :server_error}} = Bars.latest_multi(["AAPL", "MSFT"])
    end

    test "handles single symbol in list" do
      latest_multi_data = %{
        "bars" => %{
          "AAPL" => %{
            "t" => "2024-01-15T20:00:00Z",
            "o" => "185.50",
            "h" => "186.75",
            "l" => "185.00",
            "c" => "186.25",
            "v" => 2_000_000,
            "n" => 15000,
            "vw" => "185.90"
          }
        }
      }

      MockClient.mock_get_data("/v2/stocks/bars/latest", {:ok, latest_multi_data})

      assert {:ok, result} = Bars.latest_multi(["AAPL"])
      assert map_size(result) == 1
      assert %Bar{symbol: "AAPL"} = result["AAPL"]
    end
  end
end
