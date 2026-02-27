defmodule Alpa.Trading.PositionsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{Order, Position}
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Positions

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @position_response %{
    "asset_id" => "904837e3-3b76-47ec-b432-046db621571b",
    "symbol" => "AAPL",
    "exchange" => "NASDAQ",
    "asset_class" => "us_equity",
    "asset_marginable" => true,
    "qty" => "100",
    "avg_entry_price" => "175.50",
    "side" => "long",
    "market_value" => "18200.00",
    "cost_basis" => "17550.00",
    "unrealized_pl" => "650.00",
    "unrealized_plpc" => "0.037",
    "unrealized_intraday_pl" => "120.00",
    "unrealized_intraday_plpc" => "0.0066",
    "current_price" => "182.00",
    "lastday_price" => "180.80",
    "change_today" => "0.0066",
    "qty_available" => "100"
  }

  @position_response_short %{
    "asset_id" => "b28f4066-5c6d-479b-a2af-85dc1a8f16fb",
    "symbol" => "TSLA",
    "exchange" => "NASDAQ",
    "asset_class" => "us_equity",
    "asset_marginable" => true,
    "qty" => "-50",
    "avg_entry_price" => "250.00",
    "side" => "short",
    "market_value" => "-12000.00",
    "cost_basis" => "-12500.00",
    "unrealized_pl" => "500.00",
    "unrealized_plpc" => "0.04",
    "unrealized_intraday_pl" => "75.00",
    "unrealized_intraday_plpc" => "0.006",
    "current_price" => "240.00",
    "lastday_price" => "241.50",
    "change_today" => "-0.0062",
    "qty_available" => "-50"
  }

  @order_response %{
    "id" => "close-order-123",
    "client_order_id" => "client-close-456",
    "symbol" => "AAPL",
    "asset_class" => "us_equity",
    "qty" => "100",
    "filled_qty" => "0",
    "side" => "sell",
    "order_type" => "market",
    "type" => "market",
    "time_in_force" => "day",
    "status" => "new",
    "created_at" => "2024-01-15T10:30:00Z",
    "submitted_at" => "2024-01-15T10:30:00Z"
  }

  describe "list/1" do
    test "requires credentials" do
      result = Positions.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of positions" do
      MockClient.mock_get(
        "/v2/positions",
        {:ok, [@position_response, @position_response_short]}
      )

      {:ok, positions} = Positions.list(api_key: "test", api_secret: "test")

      assert length(positions) == 2

      aapl = hd(positions)
      assert %Position{} = aapl
      assert aapl.asset_id == "904837e3-3b76-47ec-b432-046db621571b"
      assert aapl.symbol == "AAPL"
      assert aapl.exchange == "NASDAQ"
      assert aapl.asset_class == "us_equity"
      assert aapl.side == :long
      assert Decimal.eq?(aapl.qty, Decimal.new("100"))
      assert Decimal.eq?(aapl.avg_entry_price, Decimal.new("175.50"))
      assert Decimal.eq?(aapl.market_value, Decimal.new("18200.00"))
      assert Decimal.eq?(aapl.cost_basis, Decimal.new("17550.00"))
      assert Decimal.eq?(aapl.unrealized_pl, Decimal.new("650.00"))
      assert Decimal.eq?(aapl.current_price, Decimal.new("182.00"))
      assert Decimal.eq?(aapl.lastday_price, Decimal.new("180.80"))
      assert Decimal.eq?(aapl.change_today, Decimal.new("0.0066"))

      tsla = Enum.at(positions, 1)
      assert %Position{} = tsla
      assert tsla.symbol == "TSLA"
      assert tsla.side == :short
      assert Decimal.eq?(tsla.qty, Decimal.new("-50"))
      assert Decimal.eq?(tsla.avg_entry_price, Decimal.new("250.00"))
    end

    test "returns empty list when no positions" do
      MockClient.mock_get("/v2/positions", {:ok, []})

      {:ok, positions} = Positions.list(api_key: "test", api_secret: "test")
      assert positions == []
    end

    test "handles invalid response (non-list)" do
      MockClient.mock_get("/v2/positions", {:ok, %{"unexpected" => "data"}})

      {:error, %Error{type: :invalid_response}} =
        Positions.list(api_key: "test", api_secret: "test")
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/positions",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} =
        Positions.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Positions.get("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a position by symbol" do
      MockClient.mock_get("/v2/positions/AAPL", {:ok, @position_response})

      {:ok, position} = Positions.get("AAPL", api_key: "test", api_secret: "test")

      assert %Position{} = position
      assert position.symbol == "AAPL"
      assert position.asset_id == "904837e3-3b76-47ec-b432-046db621571b"
      assert position.exchange == "NASDAQ"
      assert position.asset_class == "us_equity"
      assert position.side == :long
      assert Decimal.eq?(position.qty, Decimal.new("100"))
      assert Decimal.eq?(position.avg_entry_price, Decimal.new("175.50"))
      assert Decimal.eq?(position.market_value, Decimal.new("18200.00"))
      assert Decimal.eq?(position.cost_basis, Decimal.new("17550.00"))
      assert Decimal.eq?(position.unrealized_pl, Decimal.new("650.00"))
      assert Decimal.eq?(position.current_price, Decimal.new("182.00"))
      assert Decimal.eq?(position.lastday_price, Decimal.new("180.80"))
      assert Decimal.eq?(position.change_today, Decimal.new("0.0066"))
    end

    test "returns a position by asset ID" do
      asset_id = "904837e3-3b76-47ec-b432-046db621571b"
      MockClient.mock_get("/v2/positions/#{asset_id}", {:ok, @position_response})

      {:ok, position} = Positions.get(asset_id, api_key: "test", api_secret: "test")

      assert %Position{} = position
      assert position.asset_id == asset_id
      assert position.symbol == "AAPL"
    end

    test "returns a short position" do
      MockClient.mock_get("/v2/positions/TSLA", {:ok, @position_response_short})

      {:ok, position} = Positions.get("TSLA", api_key: "test", api_secret: "test")

      assert %Position{} = position
      assert position.symbol == "TSLA"
      assert position.side == :short
      assert Decimal.eq?(position.qty, Decimal.new("-50"))
    end

    test "handles not found error" do
      MockClient.mock_get(
        "/v2/positions/INVALID",
        {:error, Error.from_response(404, %{"message" => "position does not exist"})}
      )

      {:error, %Error{type: :not_found}} =
        Positions.get("INVALID", api_key: "test", api_secret: "test")
    end

    test "encodes special characters in symbol" do
      # Options symbols may contain special characters
      encoded = URI.encode_www_form("AAPL240315C00175000")
      MockClient.mock_get("/v2/positions/#{encoded}", {:ok, @position_response})

      {:ok, position} =
        Positions.get("AAPL240315C00175000", api_key: "test", api_secret: "test")

      assert %Position{} = position
    end
  end

  describe "close/2" do
    test "requires credentials" do
      result = Positions.close("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "closes a position and returns an order" do
      MockClient.mock_delete("/v2/positions/AAPL", {:ok, @order_response})

      {:ok, order} = Positions.close("AAPL", api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert order.id == "close-order-123"
      assert order.symbol == "AAPL"
      assert order.side == :sell
      assert order.order_type == :market
      assert order.status == :new
      assert Decimal.eq?(order.qty, Decimal.new("100"))
    end

    test "closes a position and returns :deleted" do
      MockClient.mock_delete("/v2/positions/AAPL", {:ok, :deleted})

      {:ok, :deleted} = Positions.close("AAPL", api_key: "test", api_secret: "test")
    end

    test "closes a partial position by qty" do
      partial_order = %{@order_response | "qty" => "10"}
      MockClient.mock_delete("/v2/positions/AAPL", {:ok, partial_order})

      {:ok, order} =
        Positions.close("AAPL", qty: 10, api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert Decimal.eq?(order.qty, Decimal.new("10"))
    end

    test "closes a partial position by percentage" do
      partial_order = %{@order_response | "qty" => "50"}
      MockClient.mock_delete("/v2/positions/AAPL", {:ok, partial_order})

      {:ok, order} =
        Positions.close("AAPL", percentage: 50, api_key: "test", api_secret: "test")

      assert %Order{} = order
      assert Decimal.eq?(order.qty, Decimal.new("50"))
    end

    test "handles not found error" do
      MockClient.mock_delete(
        "/v2/positions/NONEXISTENT",
        {:error, Error.from_response(404, %{"message" => "position does not exist"})}
      )

      {:error, %Error{type: :not_found}} =
        Positions.close("NONEXISTENT", api_key: "test", api_secret: "test")
    end

    test "handles API error" do
      MockClient.mock_delete(
        "/v2/positions/AAPL",
        {:error, Error.from_response(422, %{"message" => "cannot close position"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        Positions.close("AAPL", api_key: "test", api_secret: "test")
    end
  end

  describe "close_all/1" do
    test "requires credentials" do
      result = Positions.close_all(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "closes all positions" do
      MockClient.mock_delete(
        "/v2/positions",
        {:ok,
         [
           %{"symbol" => "AAPL", "status" => 200, "body" => @order_response},
           %{"symbol" => "TSLA", "status" => 200, "body" => %{}}
         ]}
      )

      {:ok, results} = Positions.close_all(api_key: "test", api_secret: "test")

      assert is_list(results)
      assert length(results) == 2
    end

    test "closes all positions with cancel_orders option" do
      MockClient.mock_delete("/v2/positions", {:ok, []})

      {:ok, results} =
        Positions.close_all(cancel_orders: true, api_key: "test", api_secret: "test")

      assert results == []
    end

    test "returns empty list when no positions to close" do
      MockClient.mock_delete("/v2/positions", {:ok, []})

      {:ok, results} = Positions.close_all(api_key: "test", api_secret: "test")
      assert results == []
    end

    test "handles API error" do
      MockClient.mock_delete(
        "/v2/positions",
        {:error, Error.from_response(500, %{"message" => "Internal server error"})}
      )

      {:error, %Error{type: :server_error}} =
        Positions.close_all(api_key: "test", api_secret: "test")
    end
  end

  describe "exercise/2" do
    test "requires credentials" do
      result = Positions.exercise("AAPL240315C00175000", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "exercises an options position" do
      MockClient.mock_post("/v2/positions/AAPL240315C00175000/exercise", {:ok, :exercised})

      {:ok, :exercised} =
        Positions.exercise("AAPL240315C00175000", api_key: "test", api_secret: "test")
    end

    test "handles not found error" do
      MockClient.mock_post(
        "/v2/positions/INVALID/exercise",
        {:error, Error.from_response(404, %{"message" => "position does not exist"})}
      )

      {:error, %Error{type: :not_found}} =
        Positions.exercise("INVALID", api_key: "test", api_secret: "test")
    end

    test "handles forbidden error (not an options position)" do
      MockClient.mock_post(
        "/v2/positions/AAPL/exercise",
        {:error, Error.from_response(403, %{"message" => "not an options position"})}
      )

      {:error, %Error{type: :forbidden}} =
        Positions.exercise("AAPL", api_key: "test", api_secret: "test")
    end
  end

  describe "do_not_exercise/2" do
    test "requires credentials" do
      result =
        Positions.do_not_exercise("AAPL240315C00175000", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "declines to exercise an options position" do
      MockClient.mock_post(
        "/v2/positions/AAPL240315C00175000/do-not-exercise",
        {:ok, :declined}
      )

      {:ok, :declined} =
        Positions.do_not_exercise("AAPL240315C00175000", api_key: "test", api_secret: "test")
    end

    test "handles not found error" do
      MockClient.mock_post(
        "/v2/positions/INVALID/do-not-exercise",
        {:error, Error.from_response(404, %{"message" => "position does not exist"})}
      )

      {:error, %Error{type: :not_found}} =
        Positions.do_not_exercise("INVALID", api_key: "test", api_secret: "test")
    end

    test "handles forbidden error (not an options position)" do
      MockClient.mock_post(
        "/v2/positions/AAPL/do-not-exercise",
        {:error, Error.from_response(403, %{"message" => "not an options position"})}
      )

      {:error, %Error{type: :forbidden}} =
        Positions.do_not_exercise("AAPL", api_key: "test", api_secret: "test")
    end
  end
end
