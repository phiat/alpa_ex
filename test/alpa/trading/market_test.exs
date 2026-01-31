defmodule Alpa.Trading.MarketTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{Calendar, Clock}
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Market

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @clock_open %{
    "timestamp" => "2024-01-15T14:30:00Z",
    "is_open" => true,
    "next_open" => "2024-01-16T14:30:00Z",
    "next_close" => "2024-01-15T21:00:00Z"
  }

  @clock_closed %{
    "timestamp" => "2024-01-15T22:00:00Z",
    "is_open" => false,
    "next_open" => "2024-01-16T14:30:00Z",
    "next_close" => "2024-01-16T21:00:00Z"
  }

  describe "get_clock/1" do
    test "requires credentials" do
      result = Market.get_clock(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns clock when market is open" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_open})

      {:ok, clock} = Market.get_clock(api_key: "test", api_secret: "test")

      assert %Clock{} = clock
      assert clock.is_open == true
      assert clock.timestamp != nil
      assert clock.next_open != nil
      assert clock.next_close != nil
    end

    test "returns clock when market is closed" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_closed})

      {:ok, clock} = Market.get_clock(api_key: "test", api_secret: "test")

      assert clock.is_open == false
    end

    test "handles API error" do
      MockClient.mock_get("/v2/clock", {:error, Error.from_response(500, %{"message" => "Internal Server Error"})})

      {:error, %Error{type: :server_error}} = Market.get_clock(api_key: "test", api_secret: "test")
    end
  end

  describe "open?/1" do
    test "requires credentials" do
      result = Market.open?(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns true when market is open" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_open})

      {:ok, is_open} = Market.open?(api_key: "test", api_secret: "test")

      assert is_open == true
    end

    test "returns false when market is closed" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_closed})

      {:ok, is_open} = Market.open?(api_key: "test", api_secret: "test")

      assert is_open == false
    end
  end

  describe "next_open/1" do
    test "requires credentials" do
      result = Market.next_open(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns next open datetime" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_closed})

      {:ok, next_open} = Market.next_open(api_key: "test", api_secret: "test")

      assert %DateTime{} = next_open
      assert next_open.year == 2024
    end
  end

  describe "next_close/1" do
    test "requires credentials" do
      result = Market.next_close(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns next close datetime" do
      MockClient.mock_get("/v2/clock", {:ok, @clock_open})

      {:ok, next_close} = Market.next_close(api_key: "test", api_secret: "test")

      assert %DateTime{} = next_close
      assert next_close.year == 2024
    end
  end

  describe "get_calendar/1" do
    test "requires credentials" do
      result = Market.get_calendar(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns calendar entries" do
      MockClient.mock_get("/v2/calendar", {:ok, [
        %{
          "date" => "2024-01-15",
          "open" => "09:30",
          "close" => "16:00",
          "session_open" => "04:00",
          "session_close" => "20:00"
        },
        %{
          "date" => "2024-01-16",
          "open" => "09:30",
          "close" => "16:00",
          "session_open" => "04:00",
          "session_close" => "20:00"
        }
      ]})

      {:ok, calendar} = Market.get_calendar(api_key: "test", api_secret: "test")

      assert length(calendar) == 2
      assert %Calendar{} = hd(calendar)
      assert hd(calendar).date == ~D[2024-01-15]
      assert hd(calendar).open == "09:30"
      assert hd(calendar).close == "16:00"
    end

    test "handles empty calendar" do
      MockClient.mock_get("/v2/calendar", {:ok, []})

      {:ok, calendar} = Market.get_calendar(api_key: "test", api_secret: "test")

      assert calendar == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/calendar", {:ok, %{"error" => "bad"}})

      {:error, %Error{type: :invalid_response}} = Market.get_calendar(api_key: "test", api_secret: "test")
    end
  end
end
