defmodule Alpa.Integration.CryptoTest do
  @moduledoc """
  Integration tests for Crypto Trading API endpoints.

  Run with: mix test test/integration --include live
  """
  use ExUnit.Case, async: false

  @moduletag :live

  alias Alpa.Crypto.Trading, as: CryptoTrading

  describe "Crypto Trading" do
    test "assets/0 returns crypto assets" do
      assert {:ok, assets} = CryptoTrading.assets()
      assert is_list(assets)
      assert length(assets) > 0

      IO.puts("  Crypto assets available: #{length(assets)}")

      # Find BTC and ETH
      btc = Enum.find(assets, &(&1.symbol == "BTC/USD"))
      eth = Enum.find(assets, &(&1.symbol == "ETH/USD"))

      if btc, do: IO.puts("    BTC/USD: #{btc.name}")
      if eth, do: IO.puts("    ETH/USD: #{eth.name}")
    end

    test "asset/1 returns specific crypto asset" do
      assert {:ok, asset} = CryptoTrading.asset("BTC/USD")
      assert asset.symbol == "BTC/USD"
      IO.puts("  BTC/USD: #{asset.name}")
      IO.puts("  Tradable: #{asset.tradable}, Fractionable: #{asset.fractionable}")
    end

    test "positions/0 returns crypto positions" do
      assert {:ok, positions} = CryptoTrading.positions()
      assert is_list(positions)
      IO.puts("  Crypto positions: #{length(positions)}")

      Enum.each(positions, fn pos ->
        IO.puts("    #{pos.symbol}: #{pos.qty} @ $#{pos.avg_entry_price}")
      end)
    end
  end
end
