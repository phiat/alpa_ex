defmodule Alpa.ClientTest do
  use ExUnit.Case, async: true

  alias Alpa.{Client, Error}

  describe "request without credentials" do
    test "returns missing credentials error for nil credentials" do
      result = Client.get("/v2/account", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
      assert result |> elem(1) |> Map.get(:message) =~ "credentials"
    end

    test "returns error when only api_key is set" do
      result = Client.get("/v2/account", api_key: "key", api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns error when only api_secret is set" do
      result = Client.get("/v2/account", api_key: nil, api_secret: "secret")

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns error for empty string credentials" do
      result = Client.get("/v2/account", api_key: "", api_secret: "")

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "missing credentials for post requests" do
      result = Client.post("/v2/orders", %{symbol: "AAPL"}, api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "missing credentials for delete requests" do
      result = Client.delete("/v2/orders/123", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "missing credentials for patch requests" do
      result = Client.patch("/v2/orders/123", %{qty: 10}, api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "missing credentials for market data requests" do
      result = Client.get_data("/v2/stocks/AAPL/bars", api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "error type mapping" do
    # These tests verify the Error.from_response mapping is correct
    # for different HTTP status codes

    test "401 maps to unauthorized" do
      error = Error.from_response(401, %{"message" => "Invalid API key"})
      assert error.type == :unauthorized
    end

    test "403 maps to forbidden" do
      error = Error.from_response(403, %{"message" => "Forbidden"})
      assert error.type == :forbidden
    end

    test "404 maps to not_found" do
      error = Error.from_response(404, %{"message" => "Order not found"})
      assert error.type == :not_found
    end

    test "422 maps to unprocessable_entity" do
      error = Error.from_response(422, %{"message" => "Invalid order parameters"})
      assert error.type == :unprocessable_entity
    end

    test "429 maps to rate_limited" do
      error = Error.from_response(429, %{"message" => "Too many requests"})
      assert error.type == :rate_limited
    end

    test "500 maps to server_error" do
      error = Error.from_response(500, %{"message" => "Internal server error"})
      assert error.type == :server_error
    end

    test "502 maps to server_error" do
      error = Error.from_response(502, %{"message" => "Bad gateway"})
      assert error.type == :server_error
    end

    test "503 maps to server_error" do
      error = Error.from_response(503, %{"message" => "Service unavailable"})
      assert error.type == :server_error
    end

    test "504 maps to server_error" do
      error = Error.from_response(504, %{"message" => "Gateway timeout"})
      assert error.type == :server_error
    end

    test "400 maps to unknown" do
      error = Error.from_response(400, %{"message" => "Bad request"})
      assert error.type == :unknown
    end

    test "408 maps to unknown (not timeout - that's for transport errors)" do
      error = Error.from_response(408, %{"message" => "Request timeout"})
      assert error.type == :unknown
    end
  end

  describe "error message extraction" do
    test "extracts message from map body" do
      error = Error.from_response(400, %{"message" => "Invalid symbol"})
      assert error.message == "Invalid symbol"
    end

    test "uses default message when missing" do
      error = Error.from_response(400, %{})
      assert error.message == "Unknown error"
    end

    test "uses string body as message" do
      error = Error.from_response(400, "Plain text error")
      assert error.message == "Plain text error"
    end

    test "extracts code from body when present" do
      error = Error.from_response(400, %{"message" => "Error", "code" => 40010001})
      assert error.code == 40010001
    end

    test "falls back to status code when no code in body" do
      error = Error.from_response(404, %{"message" => "Not found"})
      assert error.code == 404
    end

    test "preserves full body as details" do
      body = %{"message" => "Error", "symbol" => "AAPL", "available" => 0}
      error = Error.from_response(422, body)
      assert error.details == body
    end
  end

  describe "network and timeout errors" do
    test "timeout error has correct type and message" do
      error = Error.timeout_error()
      assert error.type == :timeout
      assert error.message == "Request timed out"
      assert error.code == nil
    end

    test "network error includes reason" do
      error = Error.network_error(:econnrefused)
      assert error.type == :network_error
      assert error.message =~ "econnrefused"
      assert error.details.reason == :econnrefused
    end

    test "network error handles complex reasons" do
      error = Error.network_error({:tls_alert, {:handshake_failure, "bad cert"}})
      assert error.type == :network_error
      assert error.message =~ "tls_alert"
    end
  end

  describe "invalid response errors" do
    test "invalid_response creates correct error" do
      error = Error.invalid_response("Expected list, got map")
      assert error.type == :invalid_response
      assert error.message =~ "Expected list"
    end

    test "invalid_response with complex data" do
      error = Error.invalid_response(%{unexpected: :data})
      assert error.type == :invalid_response
      assert error.details.reason == %{unexpected: :data}
    end
  end

  describe "error string representation" do
    test "to_string includes type, code, and message" do
      error = Error.from_response(401, %{"message" => "Invalid credentials"})
      string = to_string(error)

      assert string =~ "unauthorized"
      assert string =~ "401"
      assert string =~ "Invalid credentials"
    end

    test "to_string handles nil code" do
      error = Error.timeout_error()
      string = to_string(error)

      assert string =~ "timeout"
      assert string =~ "Request timed out"
      refute string =~ "()"
    end
  end
end
