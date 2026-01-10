defmodule Alpa.ErrorTest do
  use ExUnit.Case, async: true

  alias Alpa.Error

  describe "from_response/2" do
    test "creates unauthorized error from 401" do
      error = Error.from_response(401, %{"message" => "Unauthorized"})

      assert error.type == :unauthorized
      assert error.message == "Unauthorized"
      assert error.code == 401
    end

    test "creates forbidden error from 403" do
      error = Error.from_response(403, %{"message" => "Forbidden"})

      assert error.type == :forbidden
      assert error.message == "Forbidden"
    end

    test "creates not_found error from 404" do
      error = Error.from_response(404, %{"message" => "Not found"})

      assert error.type == :not_found
    end

    test "creates unprocessable_entity error from 422" do
      error = Error.from_response(422, %{"message" => "Invalid order"})

      assert error.type == :unprocessable_entity
    end

    test "creates rate_limited error from 429" do
      error = Error.from_response(429, %{"message" => "Too many requests"})

      assert error.type == :rate_limited
    end

    test "creates server_error from 500+" do
      error = Error.from_response(500, %{"message" => "Internal error"})
      assert error.type == :server_error

      error = Error.from_response(503, %{"message" => "Service unavailable"})
      assert error.type == :server_error
    end

    test "handles string body" do
      error = Error.from_response(400, "Bad request")

      assert error.message == "Bad request"
      assert error.details == nil
    end

    test "preserves details from map body" do
      body = %{"message" => "Error", "code" => 123, "extra" => "data"}
      error = Error.from_response(400, body)

      assert error.details == body
      assert error.code == 123
    end
  end

  describe "network_error/1" do
    test "creates network error" do
      error = Error.network_error(:econnrefused)

      assert error.type == :network_error
      assert error.message =~ "econnrefused"
      assert error.details.reason == :econnrefused
    end
  end

  describe "timeout_error/0" do
    test "creates timeout error" do
      error = Error.timeout_error()

      assert error.type == :timeout
      assert error.message == "Request timed out"
    end
  end

  describe "missing_credentials/0" do
    test "creates missing credentials error" do
      error = Error.missing_credentials()

      assert error.type == :missing_credentials
      assert error.message =~ "credentials"
    end
  end

  describe "String.Chars implementation" do
    test "formats error as string" do
      error = Error.from_response(401, %{"message" => "Unauthorized"})
      string = to_string(error)

      assert string =~ "unauthorized"
      assert string =~ "401"
      assert string =~ "Unauthorized"
    end
  end
end
