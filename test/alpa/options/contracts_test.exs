defmodule Alpa.Options.ContractsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.OptionContract
  alias Alpa.Test.MockClient
  alias Alpa.Options.Contracts

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @contract_data %{
    "id" => "opt-contract-123",
    "symbol" => "AAPL240119C00185000",
    "name" => "AAPL Jan 19 2024 185 Call",
    "status" => "active",
    "tradable" => true,
    "expiration_date" => "2024-01-19",
    "strike_price" => "185.00",
    "type" => "call",
    "style" => "american",
    "root_symbol" => "AAPL",
    "underlying_symbol" => "AAPL",
    "underlying_asset_id" => "asset-aapl-001",
    "open_interest" => 15432,
    "open_interest_date" => "2024-01-14",
    "close_price" => "3.45",
    "close_price_date" => "2024-01-14"
  }

  describe "list/1" do
    test "requires credentials" do
      result = Contracts.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns contracts with next page token" do
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => [@contract_data],
        "next_page_token" => "token-abc"
      }})

      {:ok, result} = Contracts.list(api_key: "test", api_secret: "test")

      assert length(result.contracts) == 1
      assert %OptionContract{} = hd(result.contracts)
      assert hd(result.contracts).symbol == "AAPL240119C00185000"
      assert hd(result.contracts).type == :call
      assert hd(result.contracts).style == :american
      assert Decimal.eq?(hd(result.contracts).strike_price, Decimal.new("185.00"))
      assert result.next_page_token == "token-abc"
    end

    test "returns contracts without next page token" do
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => [@contract_data]
      }})

      {:ok, result} = Contracts.list(api_key: "test", api_secret: "test")

      assert length(result.contracts) == 1
      assert result.next_page_token == nil
    end

    test "returns empty contracts" do
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => nil,
        "next_page_token" => nil
      }})

      {:ok, result} = Contracts.list(api_key: "test", api_secret: "test")

      assert result.contracts == []
      assert result.next_page_token == nil
    end

    test "handles API error" do
      MockClient.mock_get("/v2/options/contracts",
        {:error, Error.from_response(401, %{"message" => "Unauthorized"})})

      {:error, %Error{type: :unauthorized}} = Contracts.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Contracts.get("AAPL240119C00185000", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single contract" do
      MockClient.mock_get("/v2/options/contracts/AAPL240119C00185000", {:ok, @contract_data})

      {:ok, contract} = Contracts.get("AAPL240119C00185000", api_key: "test", api_secret: "test")

      assert %OptionContract{} = contract
      assert contract.symbol == "AAPL240119C00185000"
      assert contract.name == "AAPL Jan 19 2024 185 Call"
      assert contract.type == :call
      assert contract.style == :american
      assert contract.expiration_date == ~D[2024-01-19]
      assert Decimal.eq?(contract.strike_price, Decimal.new("185.00"))
      assert contract.underlying_symbol == "AAPL"
      assert contract.open_interest == 15432
    end

    test "handles not found" do
      MockClient.mock_get("/v2/options/contracts/INVALID",
        {:error, Error.from_response(404, %{"message" => "not found"})})

      {:error, %Error{type: :not_found}} = Contracts.get("INVALID", api_key: "test", api_secret: "test")
    end
  end

  describe "search/2" do
    test "requires credentials" do
      result = Contracts.search("AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "searches by underlying symbol" do
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => [@contract_data],
        "next_page_token" => nil
      }})

      {:ok, result} = Contracts.search("AAPL", api_key: "test", api_secret: "test")

      assert length(result.contracts) == 1
      assert hd(result.contracts).underlying_symbol == "AAPL"
    end

    test "converts atom type to string" do
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => [@contract_data],
        "next_page_token" => nil
      }})

      {:ok, result} = Contracts.search("AAPL", type: :call, api_key: "test", api_secret: "test")

      assert length(result.contracts) == 1
    end

    test "handles put type conversion" do
      put_contract = %{@contract_data | "type" => "put", "symbol" => "AAPL240119P00185000"}
      MockClient.mock_get("/v2/options/contracts", {:ok, %{
        "option_contracts" => [put_contract],
        "next_page_token" => nil
      }})

      {:ok, result} = Contracts.search("AAPL", type: :put, api_key: "test", api_secret: "test")

      assert hd(result.contracts).type == :put
    end
  end
end
