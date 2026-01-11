defmodule Alpa.MarketData.TradesTest do
  use ExUnit.Case, async: true

  alias Alpa.Error
  alias Alpa.MarketData.Trades

  describe "get/2" do
    test "requires credentials" do
      result = Trades.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest/2" do
    test "requires credentials" do
      result = Trades.latest("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
