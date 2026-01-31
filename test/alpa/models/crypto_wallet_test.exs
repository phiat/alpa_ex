defmodule Alpa.Models.CryptoWalletTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.CryptoWallet

  describe "from_map/1" do
    test "parses complete crypto wallet data" do
      data = %{
        "id" => "wallet-abc-123",
        "asset_id" => "asset-btc-001",
        "symbol" => "BTC",
        "status" => "active",
        "address" => "bc1qwallet123abc",
        "created_at" => "2024-01-10T08:00:00Z"
      }

      wallet = CryptoWallet.from_map(data)

      assert wallet.id == "wallet-abc-123"
      assert wallet.asset_id == "asset-btc-001"
      assert wallet.symbol == "BTC"
      assert wallet.status == "active"
      assert wallet.address == "bc1qwallet123abc"
      assert wallet.created_at.year == 2024
      assert wallet.created_at.month == 1
    end

    test "handles nil values" do
      wallet = CryptoWallet.from_map(%{})

      assert wallet.id == nil
      assert wallet.asset_id == nil
      assert wallet.symbol == nil
      assert wallet.status == nil
      assert wallet.address == nil
      assert wallet.created_at == nil
    end

    test "handles invalid datetime" do
      wallet = CryptoWallet.from_map(%{"created_at" => "bad-date"})
      assert wallet.created_at == nil
    end

    test "parses ETH wallet" do
      data = %{
        "id" => "wallet-eth-456",
        "symbol" => "ETH",
        "status" => "active",
        "address" => "0xethaddr789"
      }

      wallet = CryptoWallet.from_map(data)

      assert wallet.symbol == "ETH"
      assert wallet.address == "0xethaddr789"
    end
  end
end
