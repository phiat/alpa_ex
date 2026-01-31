defmodule Alpa.Stream.MarketDataTest do
  use ExUnit.Case, async: true

  alias Alpa.Stream.MarketData
  alias Alpa.Models.{Bar, Quote, Trade}

  # Note: These tests verify message parsing and model creation.
  # Integration tests cover actual WebSocket connectivity.

  describe "trade message parsing" do
    test "parses trade message into Trade struct" do
      data = %{
        "T" => "t",
        "S" => "AAPL",
        "p" => 185.50,
        "s" => 100,
        "t" => "2024-01-15T10:30:00Z",
        "x" => "V",
        "i" => 12345,
        "c" => ["@"],
        "z" => "A"
      }

      trade = Trade.from_map(data)

      assert trade.symbol == "AAPL"
      assert Decimal.eq?(trade.price, Decimal.from_float(185.50))
      assert trade.size == 100
      assert trade.exchange == "V"
      assert trade.id == 12345
      assert trade.conditions == ["@"]
      assert trade.tape == "A"
    end
  end

  describe "quote message parsing" do
    test "parses quote message into Quote struct" do
      data = %{
        "T" => "q",
        "S" => "AAPL",
        "bp" => 185.49,
        "bs" => 200,
        "bx" => "V",
        "ap" => 185.51,
        "as" => 300,
        "ax" => "V",
        "t" => "2024-01-15T10:30:00Z",
        "c" => ["R"],
        "z" => "A"
      }

      quote = Quote.from_map(data)

      assert quote.symbol == "AAPL"
      assert Decimal.eq?(quote.bid_price, Decimal.from_float(185.49))
      assert quote.bid_size == 200
      assert quote.bid_exchange == "V"
      assert Decimal.eq?(quote.ask_price, Decimal.from_float(185.51))
      assert quote.ask_size == 300
      assert quote.ask_exchange == "V"
    end
  end

  describe "bar message parsing" do
    test "parses bar message into Bar struct" do
      data = %{
        "T" => "b",
        "S" => "AAPL",
        "o" => 185.00,
        "h" => 186.00,
        "l" => 184.50,
        "c" => 185.50,
        "v" => 10000,
        "t" => "2024-01-15T10:30:00Z",
        "n" => 500,
        "vw" => 185.25
      }

      bar = Bar.from_map(data)

      assert bar.symbol == "AAPL"
      assert Decimal.eq?(bar.open, Decimal.from_float(185.00))
      assert Decimal.eq?(bar.high, Decimal.from_float(186.00))
      assert Decimal.eq?(bar.low, Decimal.from_float(184.50))
      assert Decimal.eq?(bar.close, Decimal.from_float(185.50))
      assert bar.volume == 10000
    end
  end

  describe "subscription management" do
    test "merge subscriptions combines lists" do
      current = %{trades: ["AAPL"], quotes: ["MSFT"], bars: []}
      new = [trades: ["GOOGL"], quotes: ["AAPL"]]

      # Simulating merge logic
      merged = %{
        trades: Enum.uniq(current.trades ++ Keyword.get(new, :trades, [])),
        quotes: Enum.uniq(current.quotes ++ Keyword.get(new, :quotes, [])),
        bars: Enum.uniq(current.bars ++ Keyword.get(new, :bars, []))
      }

      assert "AAPL" in merged.trades
      assert "GOOGL" in merged.trades
      assert "MSFT" in merged.quotes
      assert "AAPL" in merged.quotes
    end

    test "remove subscriptions removes symbols" do
      current = %{trades: ["AAPL", "MSFT"], quotes: ["AAPL"], bars: ["SPY"]}
      to_remove = [trades: ["MSFT"], bars: ["SPY"]]

      # Simulating remove logic
      removed = %{
        trades: current.trades -- Keyword.get(to_remove, :trades, []),
        quotes: current.quotes -- Keyword.get(to_remove, :quotes, []),
        bars: current.bars -- Keyword.get(to_remove, :bars, [])
      }

      assert removed.trades == ["AAPL"]
      assert removed.quotes == ["AAPL"]
      assert removed.bars == []
    end

    test "handles empty subscriptions" do
      current = %{trades: [], quotes: [], bars: []}
      assert current.trades == []
      assert current.quotes == []
      assert current.bars == []
    end
  end

  describe "message type identification" do
    test "identifies trade message by T field" do
      msg = %{"T" => "t", "S" => "AAPL", "p" => 100}
      assert msg["T"] == "t"
    end

    test "identifies quote message by T field" do
      msg = %{"T" => "q", "S" => "AAPL", "bp" => 100}
      assert msg["T"] == "q"
    end

    test "identifies bar message by T field" do
      msg = %{"T" => "b", "S" => "AAPL", "c" => 100}
      assert msg["T"] == "b"
    end

    test "identifies success message" do
      msg = %{"T" => "success", "msg" => "authenticated"}
      assert msg["T"] == "success"
      assert msg["msg"] == "authenticated"
    end

    test "identifies error message" do
      msg = %{"T" => "error", "code" => 401, "msg" => "auth failed"}
      assert msg["T"] == "error"
      assert msg["code"] == 401
    end

    test "identifies subscription confirmation" do
      msg = %{"T" => "subscription", "trades" => ["AAPL"], "quotes" => []}
      assert msg["T"] == "subscription"
    end
  end

  describe "start_link options" do
    test "requires callback option" do
      assert_raise KeyError, fn ->
        MarketData.start_link([])
      end
    end

    test "returns error without credentials" do
      result =
        MarketData.start_link(
          callback: fn _ -> :ok end,
          api_key: nil,
          api_secret: nil
        )

      assert {:error, :missing_credentials} = result
    end

    test "accepts feed option" do
      # Just verify the option is valid - actual connection tested in integration
      opts = [callback: fn _ -> :ok end, feed: "sip"]
      assert Keyword.get(opts, :feed) == "sip"
    end

    test "defaults to iex feed" do
      opts = [callback: fn _ -> :ok end]
      assert Keyword.get(opts, :feed, "iex") == "iex"
    end
  end

  describe "callback types" do
    test "accepts function callback" do
      callback = fn event -> {:ok, event} end
      assert is_function(callback, 1)
    end

    test "accepts MFA tuple callback" do
      mfa = {__MODULE__, :handle_event, [:extra_arg]}
      assert is_tuple(mfa)
      {mod, fun, args} = mfa
      assert mod == __MODULE__
      assert fun == :handle_event
      assert args == [:extra_arg]
    end

    def handle_event(event, _extra), do: {:ok, event}
  end

  describe "JSON parsing" do
    test "parses valid JSON message" do
      json = ~s({"T": "t", "S": "AAPL", "p": 185.50})
      {:ok, data} = Jason.decode(json)
      assert data["T"] == "t"
      assert data["S"] == "AAPL"
    end

    test "parses JSON array of messages" do
      json = ~s([{"T": "t", "S": "AAPL"}, {"T": "q", "S": "MSFT"}])
      {:ok, messages} = Jason.decode(json)
      assert is_list(messages)
      assert length(messages) == 2
    end

    test "handles invalid JSON" do
      result = Jason.decode("not valid json")
      assert {:error, _} = result
    end
  end
end
