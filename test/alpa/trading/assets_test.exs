defmodule Alpa.Trading.AssetsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Asset
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Assets

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  describe "list/1" do
    test "requires credentials" do
      result = Assets.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of assets" do
      MockClient.mock_get(
        "/v2/assets",
        {:ok,
         [
           %{
             "id" => "asset-1",
             "class" => "us_equity",
             "symbol" => "AAPL",
             "name" => "Apple Inc.",
             "exchange" => "NASDAQ",
             "status" => "active",
             "tradable" => true,
             "marginable" => true,
             "shortable" => true,
             "easy_to_borrow" => true,
             "fractionable" => true
           },
           %{
             "id" => "asset-2",
             "class" => "us_equity",
             "symbol" => "MSFT",
             "name" => "Microsoft Corp.",
             "exchange" => "NASDAQ",
             "status" => "active",
             "tradable" => true
           }
         ]}
      )

      {:ok, assets} = Assets.list(api_key: "test", api_secret: "test")

      assert length(assets) == 2
      assert %Asset{} = hd(assets)
      assert hd(assets).symbol == "AAPL"
      assert hd(assets).class == :us_equity
      assert hd(assets).status == :active
      assert Enum.at(assets, 1).symbol == "MSFT"
    end

    test "handles empty list" do
      MockClient.mock_get("/v2/assets", {:ok, []})
      {:ok, assets} = Assets.list(api_key: "test", api_secret: "test")
      assert assets == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/assets", {:ok, %{"unexpected" => "data"}})
      {:error, %Error{type: :invalid_response}} = Assets.list(api_key: "test", api_secret: "test")
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/assets",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})}
      )

      {:error, %Error{type: :unauthorized}} = Assets.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Assets.get("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single asset by symbol" do
      MockClient.mock_get(
        "/v2/assets/AAPL",
        {:ok,
         %{
           "id" => "asset-1",
           "class" => "us_equity",
           "symbol" => "AAPL",
           "name" => "Apple Inc.",
           "exchange" => "NASDAQ",
           "status" => "active",
           "tradable" => true,
           "fractionable" => true,
           "min_order_size" => "1",
           "min_trade_increment" => "1",
           "price_increment" => "0.01"
         }}
      )

      {:ok, asset} = Assets.get("AAPL", api_key: "test", api_secret: "test")

      assert %Asset{} = asset
      assert asset.symbol == "AAPL"
      assert asset.name == "Apple Inc."
      assert asset.exchange == "NASDAQ"
      assert asset.tradable == true
      assert Decimal.eq?(asset.min_order_size, Decimal.new("1"))
      assert Decimal.eq?(asset.price_increment, Decimal.new("0.01"))
    end

    test "handles not found error" do
      MockClient.mock_get(
        "/v2/assets/INVALID",
        {:error, Error.from_response(404, %{"message" => "asset not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Assets.get("INVALID", api_key: "test", api_secret: "test")
    end
  end
end
