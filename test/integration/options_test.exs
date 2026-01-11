defmodule Alpa.Integration.OptionsTest do
  @moduledoc """
  Integration tests for Options API endpoints.

  Run with: mix test test/integration --include live
  """
  use ExUnit.Case, async: false

  @moduletag :live

  alias Alpa.Options.Contracts

  describe "Options Contracts" do
    test "list/1 returns option contracts" do
      # Get AAPL options
      assert {:ok, result} = Contracts.list(
        underlying_symbols: ["AAPL"],
        status: "active",
        limit: 10
      )

      assert is_list(result.contracts)
      IO.puts("  AAPL option contracts: #{length(result.contracts)}")

      if length(result.contracts) > 0 do
        [contract | _] = result.contracts
        IO.puts("    First: #{contract.symbol}")
        IO.puts("    Type: #{contract.type}, Strike: $#{contract.strike_price}")
        IO.puts("    Expiration: #{contract.expiration_date}")
      end
    end

    test "search/2 searches for specific options" do
      # Search for AAPL calls
      assert {:ok, result} = Contracts.search("AAPL",
        type: :call,
        limit: 5
      )

      assert is_list(result.contracts)
      IO.puts("  AAPL call options found: #{length(result.contracts)}")

      Enum.take(result.contracts, 3)
      |> Enum.each(fn contract ->
        IO.puts("    #{contract.symbol}: Strike $#{contract.strike_price}, Exp #{contract.expiration_date}")
      end)
    end

    test "get/1 returns specific contract" do
      # First get a contract symbol from search
      {:ok, result} = Contracts.search("AAPL", type: :call, limit: 1)

      if length(result.contracts) > 0 do
        [contract | _] = result.contracts

        assert {:ok, fetched} = Contracts.get(contract.symbol)
        assert fetched.symbol == contract.symbol
        IO.puts("  Fetched contract: #{fetched.symbol}")
        IO.puts("    Underlying: #{fetched.underlying_symbol}")
        IO.puts("    Strike: $#{fetched.strike_price}")
        IO.puts("    Type: #{fetched.type}")
      else
        IO.puts("  No contracts available to fetch")
      end
    end
  end
end
