defmodule AlpaTest do
  use ExUnit.Case, async: true

  describe "module structure" do
    setup do
      # Ensure the module is loaded before checking exports
      {:module, _} = Code.ensure_loaded(Alpa)
      :ok
    end

    test "exports account functions" do
      assert function_exported?(Alpa, :account, 0)
      assert function_exported?(Alpa, :account, 1)
    end

    test "exports order functions" do
      assert function_exported?(Alpa, :orders, 0)
      assert function_exported?(Alpa, :orders, 1)
      assert function_exported?(Alpa, :buy, 2)
      assert function_exported?(Alpa, :buy, 3)
      assert function_exported?(Alpa, :sell, 2)
      assert function_exported?(Alpa, :sell, 3)
    end

    test "exports position functions" do
      assert function_exported?(Alpa, :positions, 0)
      assert function_exported?(Alpa, :positions, 1)
    end

    test "exports market functions" do
      assert function_exported?(Alpa, :clock, 0)
      assert function_exported?(Alpa, :clock, 1)
    end

    test "exports market data functions" do
      assert function_exported?(Alpa, :bars, 1)
      assert function_exported?(Alpa, :bars, 2)
      assert function_exported?(Alpa, :snapshot, 1)
      assert function_exported?(Alpa, :snapshot, 2)
    end

    test "exports watchlist functions" do
      assert function_exported?(Alpa, :watchlists, 0)
      assert function_exported?(Alpa, :watchlists, 1)
    end
  end
end
