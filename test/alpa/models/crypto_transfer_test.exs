defmodule Alpa.Models.CryptoTransferTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.CryptoTransfer

  describe "from_map/1" do
    test "parses complete crypto transfer data" do
      data = %{
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

      transfer = CryptoTransfer.from_map(data)

      assert transfer.id == "transfer-abc-123"
      assert transfer.tx_hash == "0xabc123def456789"
      assert transfer.direction == "OUTGOING"
      assert transfer.status == "completed"
      assert Decimal.eq?(transfer.amount, Decimal.new("0.5"))
      assert transfer.symbol == "BTC"
      assert Decimal.eq?(transfer.network_fee, Decimal.new("0.0001"))
      assert Decimal.eq?(transfer.fees, Decimal.new("0.001"))
      assert transfer.chain == "BTC"
      assert transfer.from_address == "bc1qsender123"
      assert transfer.to_address == "bc1qrecipient456"
      assert transfer.created_at.year == 2024
      assert transfer.updated_at.year == 2024
    end

    test "parses incoming transfer" do
      data = %{
        "id" => "transfer-def-456",
        "direction" => "INCOMING",
        "status" => "pending",
        "amount" => "1.25",
        "symbol" => "ETH",
        "chain" => "ETH",
        "to_address" => "0xmyethaddr123"
      }

      transfer = CryptoTransfer.from_map(data)

      assert transfer.direction == "INCOMING"
      assert transfer.status == "pending"
      assert Decimal.eq?(transfer.amount, Decimal.new("1.25"))
      assert transfer.symbol == "ETH"
    end

    test "handles nil values" do
      transfer = CryptoTransfer.from_map(%{})

      assert transfer.id == nil
      assert transfer.tx_hash == nil
      assert transfer.direction == nil
      assert transfer.status == nil
      assert transfer.amount == nil
      assert transfer.symbol == nil
      assert transfer.network_fee == nil
      assert transfer.fees == nil
      assert transfer.created_at == nil
      assert transfer.updated_at == nil
    end

    test "handles invalid datetime" do
      transfer = CryptoTransfer.from_map(%{"created_at" => "invalid"})
      assert transfer.created_at == nil
    end
  end
end
