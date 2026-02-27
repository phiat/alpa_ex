defmodule Alpa.MarketData.QuotesTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Quote
  alias Alpa.Test.MockClient
  alias Alpa.MarketData.Quotes

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  # ── get/2 ──────────────────────────────────────────────────────────────

  describe "get/2" do
    test "requires credentials" do
      result = Quotes.get("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed quotes for a symbol" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:ok, %{
        "quotes" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "ap" => "185.50",
            "as" => 2,
            "ax" => "Q",
            "bp" => "185.45",
            "bs" => 3,
            "bx" => "K",
            "c" => ["R"],
            "z" => "A"
          },
          %{
            "t" => "2024-01-15T14:30:01Z",
            "ap" => "185.55",
            "as" => 1,
            "ax" => "Q",
            "bp" => "185.48",
            "bs" => 5,
            "bx" => "N",
            "c" => ["R"],
            "z" => "A"
          }
        ]
      }})

      assert {:ok, quotes} = Quotes.get("AAPL")
      assert length(quotes) == 2

      [first, second] = quotes

      assert %Quote{} = first
      assert first.symbol == "AAPL"
      assert first.timestamp == ~U[2024-01-15 14:30:00Z]
      assert first.ask_price == Decimal.new("185.50")
      assert first.ask_size == 2
      assert first.ask_exchange == "Q"
      assert first.bid_price == Decimal.new("185.45")
      assert first.bid_size == 3
      assert first.bid_exchange == "K"
      assert first.conditions == ["R"]
      assert first.tape == "A"

      assert %Quote{} = second
      assert second.symbol == "AAPL"
      assert second.timestamp == ~U[2024-01-15 14:30:01Z]
      assert second.ask_price == Decimal.new("185.55")
    end

    test "returns empty list when quotes is nil" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:ok, %{"quotes" => nil}})

      assert {:ok, []} = Quotes.get("AAPL")
    end

    test "returns empty list when response has no quotes key" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:ok, %{}})

      assert {:ok, []} = Quotes.get("AAPL")
    end

    test "returns empty list when quotes is empty" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:ok, %{"quotes" => []}})

      assert {:ok, []} = Quotes.get("AAPL")
    end

    test "passes through API errors" do
      error = %Error{type: :not_found, message: "Symbol not found", code: 404, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:error, error})

      assert {:error, %Error{type: :not_found}} = Quotes.get("AAPL")
    end

    test "URL-encodes symbols with special characters" do
      MockClient.mock_get_data("/v2/stocks/BRK%2FB/quotes", {:ok, %{
        "quotes" => [
          %{
            "t" => "2024-01-15T14:30:00Z",
            "ap" => "400.00",
            "as" => 1,
            "ax" => "Q",
            "bp" => "399.95",
            "bs" => 1,
            "bx" => "K",
            "c" => [],
            "z" => "A"
          }
        ]
      }})

      assert {:ok, [%Quote{symbol: "BRK/B"}]} = Quotes.get("BRK/B")
    end

    test "passes through rate limit errors" do
      error = %Error{type: :rate_limited, message: "Too many requests", code: 429, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes", {:error, error})

      assert {:error, %Error{type: :rate_limited}} = Quotes.get("AAPL")
    end
  end

  # ── get_multi/2 ────────────────────────────────────────────────────────

  describe "get_multi/2" do
    test "requires credentials" do
      result = Quotes.get_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed quotes grouped by symbol" do
      MockClient.mock_get_data("/v2/stocks/quotes", {:ok, %{
        "quotes" => %{
          "AAPL" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "ap" => "185.50",
              "as" => 2,
              "ax" => "Q",
              "bp" => "185.45",
              "bs" => 3,
              "bx" => "K",
              "c" => ["R"],
              "z" => "A"
            }
          ],
          "MSFT" => [
            %{
              "t" => "2024-01-15T14:30:00Z",
              "ap" => "380.00",
              "as" => 4,
              "ax" => "N",
              "bp" => "379.95",
              "bs" => 2,
              "bx" => "Q",
              "c" => [],
              "z" => "B"
            },
            %{
              "t" => "2024-01-15T14:30:01Z",
              "ap" => "380.10",
              "as" => 1,
              "ax" => "N",
              "bp" => "380.00",
              "bs" => 3,
              "bx" => "Q",
              "c" => [],
              "z" => "B"
            }
          ]
        }
      }})

      assert {:ok, result} = Quotes.get_multi(["AAPL", "MSFT"])
      assert is_map(result)
      assert Map.has_key?(result, "AAPL")
      assert Map.has_key?(result, "MSFT")

      assert [%Quote{symbol: "AAPL"} = aapl_quote] = result["AAPL"]
      assert aapl_quote.ask_price == Decimal.new("185.50")
      assert aapl_quote.bid_price == Decimal.new("185.45")

      assert [first_msft, second_msft] = result["MSFT"]
      assert %Quote{symbol: "MSFT"} = first_msft
      assert first_msft.ask_price == Decimal.new("380.00")
      assert %Quote{symbol: "MSFT"} = second_msft
      assert second_msft.ask_price == Decimal.new("380.10")
    end

    test "returns empty map when quotes is nil" do
      MockClient.mock_get_data("/v2/stocks/quotes", {:ok, %{"quotes" => nil}})

      assert {:ok, %{}} = Quotes.get_multi(["AAPL", "MSFT"])
    end

    test "returns empty map when response has no quotes key" do
      MockClient.mock_get_data("/v2/stocks/quotes", {:ok, %{}})

      assert {:ok, %{}} = Quotes.get_multi(["AAPL"])
    end

    test "returns empty map when quotes map is empty" do
      MockClient.mock_get_data("/v2/stocks/quotes", {:ok, %{"quotes" => %{}}})

      assert {:ok, %{}} = Quotes.get_multi(["AAPL"])
    end

    test "passes through API errors" do
      error = %Error{type: :server_error, message: "Internal error", code: 500, details: nil}
      MockClient.mock_get_data("/v2/stocks/quotes", {:error, error})

      assert {:error, %Error{type: :server_error}} = Quotes.get_multi(["AAPL", "MSFT"])
    end
  end

  # ── latest/2 ───────────────────────────────────────────────────────────

  describe "latest/2" do
    test "requires credentials" do
      result = Quotes.latest("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single parsed quote" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes/latest", {:ok, %{
        "quote" => %{
          "t" => "2024-01-15T20:00:00Z",
          "ap" => "186.00",
          "as" => 5,
          "ax" => "V",
          "bp" => "185.99",
          "bs" => 10,
          "bx" => "Q",
          "c" => ["R"],
          "z" => "A"
        }
      }})

      assert {:ok, %Quote{} = quote} = Quotes.latest("AAPL")
      assert quote.symbol == "AAPL"
      assert quote.timestamp == ~U[2024-01-15 20:00:00Z]
      assert quote.ask_price == Decimal.new("186.00")
      assert quote.ask_size == 5
      assert quote.ask_exchange == "V"
      assert quote.bid_price == Decimal.new("185.99")
      assert quote.bid_size == 10
      assert quote.bid_exchange == "Q"
      assert quote.conditions == ["R"]
      assert quote.tape == "A"
    end

    test "returns invalid_response error when quote key is missing" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes/latest", {:ok, %{"something_else" => %{}}})

      assert {:error, %Error{type: :invalid_response}} = Quotes.latest("AAPL")
    end

    test "returns invalid_response error for empty response" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Quotes.latest("AAPL")
    end

    test "passes through API errors" do
      error = %Error{type: :unauthorized, message: "Unauthorized", code: 401, details: nil}
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes/latest", {:error, error})

      assert {:error, %Error{type: :unauthorized}} = Quotes.latest("AAPL")
    end

    test "URL-encodes symbols with special characters" do
      MockClient.mock_get_data("/v2/stocks/BRK%2FB/quotes/latest", {:ok, %{
        "quote" => %{
          "t" => "2024-01-15T20:00:00Z",
          "ap" => "400.00",
          "as" => 1,
          "ax" => "Q",
          "bp" => "399.95",
          "bs" => 1,
          "bx" => "K",
          "c" => [],
          "z" => "A"
        }
      }})

      assert {:ok, %Quote{symbol: "BRK/B"}} = Quotes.latest("BRK/B")
    end

    test "handles quote with nil fields gracefully" do
      MockClient.mock_get_data("/v2/stocks/AAPL/quotes/latest", {:ok, %{
        "quote" => %{
          "t" => nil,
          "ap" => nil,
          "as" => nil,
          "ax" => nil,
          "bp" => nil,
          "bs" => nil,
          "bx" => nil,
          "c" => nil,
          "z" => nil
        }
      }})

      assert {:ok, %Quote{} = quote} = Quotes.latest("AAPL")
      assert quote.symbol == "AAPL"
      assert quote.timestamp == nil
      assert quote.ask_price == nil
      assert quote.ask_size == nil
      assert quote.bid_price == nil
      assert quote.bid_size == nil
      assert quote.conditions == nil
      assert quote.tape == nil
    end
  end

  # ── latest_multi/2 ─────────────────────────────────────────────────────

  describe "latest_multi/2" do
    test "requires credentials" do
      result = Quotes.latest_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns parsed quotes keyed by symbol" do
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:ok, %{
        "quotes" => %{
          "AAPL" => %{
            "t" => "2024-01-15T20:00:00Z",
            "ap" => "186.00",
            "as" => 5,
            "ax" => "V",
            "bp" => "185.99",
            "bs" => 10,
            "bx" => "Q",
            "c" => ["R"],
            "z" => "A"
          },
          "MSFT" => %{
            "t" => "2024-01-15T20:00:00Z",
            "ap" => "380.25",
            "as" => 3,
            "ax" => "N",
            "bp" => "380.20",
            "bs" => 7,
            "bx" => "Q",
            "c" => [],
            "z" => "B"
          }
        }
      }})

      assert {:ok, result} = Quotes.latest_multi(["AAPL", "MSFT"])
      assert is_map(result)

      assert %Quote{} = aapl = result["AAPL"]
      assert aapl.symbol == "AAPL"
      assert aapl.ask_price == Decimal.new("186.00")
      assert aapl.bid_price == Decimal.new("185.99")
      assert aapl.ask_size == 5
      assert aapl.bid_size == 10

      assert %Quote{} = msft = result["MSFT"]
      assert msft.symbol == "MSFT"
      assert msft.ask_price == Decimal.new("380.25")
      assert msft.bid_price == Decimal.new("380.20")
      assert msft.tape == "B"
    end

    test "returns invalid_response error when quotes key is missing" do
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:ok, %{"bad_key" => %{}}})

      assert {:error, %Error{type: :invalid_response}} = Quotes.latest_multi(["AAPL"])
    end

    test "returns invalid_response error for empty response" do
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:ok, %{}})

      assert {:error, %Error{type: :invalid_response}} = Quotes.latest_multi(["AAPL"])
    end

    test "passes through API errors" do
      error = %Error{type: :forbidden, message: "Forbidden", code: 403, details: nil}
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:error, error})

      assert {:error, %Error{type: :forbidden}} = Quotes.latest_multi(["AAPL", "MSFT"])
    end

    test "handles single symbol" do
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:ok, %{
        "quotes" => %{
          "TSLA" => %{
            "t" => "2024-01-15T20:00:00Z",
            "ap" => "250.00",
            "as" => 2,
            "ax" => "Q",
            "bp" => "249.95",
            "bs" => 4,
            "bx" => "N",
            "c" => ["R"],
            "z" => "C"
          }
        }
      }})

      assert {:ok, result} = Quotes.latest_multi(["TSLA"])
      assert map_size(result) == 1
      assert %Quote{symbol: "TSLA", tape: "C"} = result["TSLA"]
    end

    test "passes through network errors" do
      error = %Error{type: :network_error, message: "Network error: :econnrefused", code: nil, details: nil}
      MockClient.mock_get_data("/v2/stocks/quotes/latest", {:error, error})

      assert {:error, %Error{type: :network_error}} = Quotes.latest_multi(["AAPL"])
    end
  end
end
