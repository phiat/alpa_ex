defmodule Alpa.ClientTest do
  use ExUnit.Case, async: true

  alias Alpa.{Client, Error}

  setup_all do
    {:module, _} = Code.ensure_loaded(Client)
    :ok
  end

  describe "request without credentials" do
    test "returns missing credentials error" do
      result = Client.get("/v2/account", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns error when only api_key is set" do
      result = Client.get("/v2/account", api_key: "key", api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns error when only api_secret is set" do
      result = Client.get("/v2/account", api_key: nil, api_secret: "secret")

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get/2" do
    test "function exists with correct arity" do
      assert function_exported?(Client, :get, 1)
      assert function_exported?(Client, :get, 2)
    end
  end

  describe "post/3" do
    test "function exists with correct arity" do
      assert function_exported?(Client, :post, 1)
      assert function_exported?(Client, :post, 2)
      assert function_exported?(Client, :post, 3)
    end
  end

  describe "patch/3" do
    test "function exists with correct arity" do
      assert function_exported?(Client, :patch, 2)
      assert function_exported?(Client, :patch, 3)
    end
  end

  describe "delete/2" do
    test "function exists with correct arity" do
      assert function_exported?(Client, :delete, 1)
      assert function_exported?(Client, :delete, 2)
    end
  end

  describe "get_data/2" do
    test "function exists with correct arity" do
      assert function_exported?(Client, :get_data, 1)
      assert function_exported?(Client, :get_data, 2)
    end
  end
end
