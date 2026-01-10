defmodule Alpa.MarketData.QuotesTest do
  use ExUnit.Case, async: true

  alias Alpa.MarketData.Quotes
  alias Alpa.Error

  describe "get/2" do
    test "requires credentials" do
      result = Quotes.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "latest/2" do
    test "requires credentials" do
      result = Quotes.latest("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
