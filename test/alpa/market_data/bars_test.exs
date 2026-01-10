defmodule Alpa.MarketData.BarsTest do
  use ExUnit.Case, async: true

  alias Alpa.MarketData.Bars
  alias Alpa.Error

  describe "get/2" do
    test "requires credentials" do
      result = Bars.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_multi/2" do
    test "requires credentials" do
      result = Bars.get_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest/2" do
    test "requires credentials" do
      result = Bars.latest("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest_multi/2" do
    test "requires credentials" do
      result = Bars.latest_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
