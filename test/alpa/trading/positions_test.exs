defmodule Alpa.Trading.PositionsTest do
  use ExUnit.Case, async: true

  alias Alpa.Trading.Positions
  alias Alpa.Error

  describe "list/1" do
    test "requires credentials" do
      result = Positions.list(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Positions.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "close/2" do
    test "requires credentials" do
      result = Positions.close("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "close_all/1" do
    test "requires credentials" do
      result = Positions.close_all(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
