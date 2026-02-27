defmodule Alpa.Crypto.FundingTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{CryptoTransfer, CryptoWallet}
  alias Alpa.Test.MockClient
  alias Alpa.Crypto.Funding

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @wallet_data %{
    "id" => "wallet-btc-123",
    "asset_id" => "asset-btc-001",
    "symbol" => "BTC",
    "status" => "active",
    "address" => "bc1qwallet123abc",
    "created_at" => "2024-01-10T08:00:00Z"
  }

  @transfer_data %{
    "id" => "transfer-abc-123",
    "tx_hash" => "0xabc123def456789",
    "direction" => "OUTGOING",
    "status" => "completed",
    "amount" => "0.5",
    "symbol" => "BTC",
    "network_fee" => "0.0001",
    "fees" => "0.001",
    "chain" => "BTC",
    "from_address" => "bc1qsender123",
    "to_address" => "bc1qrecipient456",
    "created_at" => "2024-01-15T10:00:00Z",
    "updated_at" => "2024-01-15T10:30:00Z"
  }

  describe "list_wallets/1" do
    test "requires credentials" do
      result = Funding.list_wallets(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of wallets" do
      MockClient.mock_get("/v2/crypto/funding/wallets", {:ok, [@wallet_data]})

      {:ok, wallets} = Funding.list_wallets(api_key: "test", api_secret: "test")

      assert length(wallets) == 1
      assert %CryptoWallet{} = hd(wallets)
      assert hd(wallets).id == "wallet-btc-123"
      assert hd(wallets).symbol == "BTC"
      assert hd(wallets).status == "active"
      assert hd(wallets).address == "bc1qwallet123abc"
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/crypto/funding/wallets", {:ok, []})
      {:ok, wallets} = Funding.list_wallets(api_key: "test", api_secret: "test")
      assert wallets == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/crypto/funding/wallets", {:ok, %{"error" => "bad"}})

      {:error, %Error{type: :invalid_response}} =
        Funding.list_wallets(api_key: "test", api_secret: "test")
    end
  end

  describe "list_transfers/1" do
    test "requires credentials" do
      result = Funding.list_transfers(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of transfers" do
      MockClient.mock_get("/v2/crypto/funding/transfers", {:ok, [@transfer_data]})

      {:ok, transfers} = Funding.list_transfers(api_key: "test", api_secret: "test")

      assert length(transfers) == 1
      assert %CryptoTransfer{} = hd(transfers)
      assert hd(transfers).id == "transfer-abc-123"
      assert hd(transfers).direction == "OUTGOING"
      assert Decimal.eq?(hd(transfers).amount, Decimal.new("0.5"))
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/crypto/funding/transfers", {:ok, []})
      {:ok, transfers} = Funding.list_transfers(api_key: "test", api_secret: "test")
      assert transfers == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/crypto/funding/transfers", {:ok, %{"error" => "bad"}})

      {:error, %Error{type: :invalid_response}} =
        Funding.list_transfers(api_key: "test", api_secret: "test")
    end
  end

  describe "get_transfer/2" do
    test "requires credentials" do
      result = Funding.get_transfer("transfer-abc-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single transfer" do
      MockClient.mock_get("/v2/crypto/funding/transfers/transfer-abc-123", {:ok, @transfer_data})

      {:ok, transfer} =
        Funding.get_transfer("transfer-abc-123", api_key: "test", api_secret: "test")

      assert %CryptoTransfer{} = transfer
      assert transfer.id == "transfer-abc-123"
      assert transfer.tx_hash == "0xabc123def456789"
      assert transfer.status == "completed"
      assert Decimal.eq?(transfer.amount, Decimal.new("0.5"))
      assert transfer.symbol == "BTC"
      assert transfer.chain == "BTC"
    end

    test "handles not found" do
      MockClient.mock_get(
        "/v2/crypto/funding/transfers/nonexistent",
        {:error, Error.from_response(404, %{"message" => "not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Funding.get_transfer("nonexistent", api_key: "test", api_secret: "test")
    end
  end

  describe "create_transfer/1" do
    test "requires credentials" do
      result =
        Funding.create_transfer(
          amount: "0.5",
          address: "bc1q123",
          symbol: "BTC",
          api_key: nil,
          api_secret: nil
        )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "creates a withdrawal transfer" do
      new_transfer = %{
        "id" => "transfer-new-789",
        "direction" => "OUTGOING",
        "status" => "pending",
        "amount" => "0.5",
        "symbol" => "BTC",
        "chain" => "BTC",
        "to_address" => "bc1qrecipient456",
        "created_at" => "2024-01-15T15:00:00Z"
      }

      MockClient.mock_post("/v2/crypto/funding/transfers", {:ok, new_transfer})

      {:ok, transfer} =
        Funding.create_transfer(
          amount: "0.5",
          address: "bc1qrecipient456",
          symbol: "BTC",
          api_key: "test",
          api_secret: "test"
        )

      assert %CryptoTransfer{} = transfer
      assert transfer.id == "transfer-new-789"
      assert transfer.status == "pending"
      assert Decimal.eq?(transfer.amount, Decimal.new("0.5"))
    end

    test "handles API error" do
      MockClient.mock_post(
        "/v2/crypto/funding/transfers",
        {:error, Error.from_response(422, %{"message" => "insufficient balance"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        Funding.create_transfer(
          amount: "100",
          address: "bc1q123",
          symbol: "BTC",
          api_key: "test",
          api_secret: "test"
        )
    end
  end

  describe "list_whitelists/1" do
    test "requires credentials" do
      result = Funding.list_whitelists(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of whitelisted addresses" do
      whitelist_data = [
        %{
          "address" => "bc1qwhitelist123",
          "asset" => "BTC",
          "created_at" => "2024-02-01T12:00:00Z"
        },
        %{
          "address" => "0xethwhitelist456",
          "asset" => "ETH",
          "created_at" => "2024-02-02T12:00:00Z"
        }
      ]

      MockClient.mock_get("/v2/crypto/funding/whitelists", {:ok, whitelist_data})

      {:ok, whitelists} = Funding.list_whitelists(api_key: "test", api_secret: "test")

      assert length(whitelists) == 2
      assert hd(whitelists)["address"] == "bc1qwhitelist123"
      assert hd(whitelists)["asset"] == "BTC"
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/crypto/funding/whitelists", {:ok, []})
      {:ok, whitelists} = Funding.list_whitelists(api_key: "test", api_secret: "test")
      assert whitelists == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/crypto/funding/whitelists", {:ok, %{"error" => "bad"}})

      {:error, %Error{type: :invalid_response}} =
        Funding.list_whitelists(api_key: "test", api_secret: "test")
    end
  end

  describe "create_whitelist/1" do
    test "requires credentials" do
      result =
        Funding.create_whitelist(
          address: "bc1qwhitelist123",
          asset: "BTC",
          api_key: nil,
          api_secret: nil
        )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "creates a whitelisted address" do
      whitelist_entry = %{
        "address" => "bc1qwhitelist123",
        "asset" => "BTC",
        "status" => "active",
        "created_at" => "2024-02-01T12:00:00Z"
      }

      MockClient.mock_post("/v2/crypto/funding/whitelists", {:ok, whitelist_entry})

      {:ok, whitelist} =
        Funding.create_whitelist(
          address: "bc1qwhitelist123",
          asset: "BTC",
          api_key: "test",
          api_secret: "test"
        )

      assert is_map(whitelist)
      assert whitelist["address"] == "bc1qwhitelist123"
      assert whitelist["asset"] == "BTC"
      assert whitelist["status"] == "active"
    end

    test "handles API error" do
      MockClient.mock_post(
        "/v2/crypto/funding/whitelists",
        {:error, Error.from_response(422, %{"message" => "address already whitelisted"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        Funding.create_whitelist(
          address: "bc1qwhitelist123",
          asset: "BTC",
          api_key: "test",
          api_secret: "test"
        )
    end
  end

  describe "delete_whitelist/2" do
    test "requires credentials" do
      result = Funding.delete_whitelist("bc1qwhitelist123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "deletes a whitelisted address and returns data" do
      delete_response = %{
        "address" => "bc1qwhitelist123",
        "asset" => "BTC",
        "status" => "deleted"
      }

      MockClient.mock_delete(
        "/v2/crypto/funding/whitelists/bc1qwhitelist123",
        {:ok, delete_response}
      )

      {:ok, result} =
        Funding.delete_whitelist("bc1qwhitelist123", api_key: "test", api_secret: "test")

      assert is_map(result)
      assert result["address"] == "bc1qwhitelist123"
      assert result["status"] == "deleted"
    end

    test "returns empty map on :deleted response" do
      MockClient.mock_delete(
        "/v2/crypto/funding/whitelists/bc1qwhitelist123",
        {:ok, :deleted}
      )

      {:ok, result} =
        Funding.delete_whitelist("bc1qwhitelist123", api_key: "test", api_secret: "test")

      assert result == %{}
    end

    test "URL-encodes the address" do
      MockClient.mock_delete(
        "/v2/crypto/funding/whitelists/bc1q%2Bspecial%3Daddr",
        {:ok, :deleted}
      )

      {:ok, result} =
        Funding.delete_whitelist("bc1q+special=addr", api_key: "test", api_secret: "test")

      assert result == %{}
    end

    test "handles not found" do
      MockClient.mock_delete(
        "/v2/crypto/funding/whitelists/nonexistent",
        {:error, Error.from_response(404, %{"message" => "not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Funding.delete_whitelist("nonexistent", api_key: "test", api_secret: "test")
    end
  end

  describe "estimate_transfer/2" do
    test "requires credentials" do
      result = Funding.estimate_transfer("transfer-abc-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns fee estimate for a transfer" do
      estimate_data = %{
        "fee" => "0.0001",
        "total_fee" => "0.0002",
        "currency" => "BTC",
        "gas_price" => "50"
      }

      MockClient.mock_get(
        "/v2/crypto/funding/transfers/transfer-abc-123/estimate",
        {:ok, estimate_data}
      )

      {:ok, estimate} =
        Funding.estimate_transfer("transfer-abc-123", api_key: "test", api_secret: "test")

      assert is_map(estimate)
      assert estimate["fee"] == "0.0001"
      assert estimate["total_fee"] == "0.0002"
      assert estimate["currency"] == "BTC"
    end

    test "handles not found" do
      MockClient.mock_get(
        "/v2/crypto/funding/transfers/nonexistent/estimate",
        {:error, Error.from_response(404, %{"message" => "not found"})}
      )

      {:error, %Error{type: :not_found}} =
        Funding.estimate_transfer("nonexistent", api_key: "test", api_secret: "test")
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/crypto/funding/transfers/transfer-abc-123/estimate",
        {:error, Error.from_response(500, %{"message" => "internal server error"})}
      )

      {:error, %Error{}} =
        Funding.estimate_transfer("transfer-abc-123", api_key: "test", api_secret: "test")
    end
  end
end
