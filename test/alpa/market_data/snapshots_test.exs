defmodule Alpa.MarketData.SnapshotsTest do
  use ExUnit.Case, async: true

  alias Alpa.Error
  alias Alpa.MarketData.Snapshots

  describe "get/2" do
    test "requires credentials" do
      result = Snapshots.get("AAPL", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_multi/2" do
    test "requires credentials" do
      result = Snapshots.get_multi(["AAPL", "MSFT"], api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
