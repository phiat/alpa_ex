defmodule Alpa.ClientTest do
  use ExUnit.Case, async: false

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
      error = Error.from_response(400, %{"message" => "Error", "code" => 40_010_001})
      assert error.code == 40_010_001
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

  # ---------------------------------------------------------------------------
  # New tests below: exercise Client through the real code path by mocking
  # Req.request/1 with :meck so we control HTTP responses end-to-end.
  # ---------------------------------------------------------------------------

  @valid_creds [api_key: "test-key", api_secret: "test-secret"]

  describe "successful HTTP responses (mocked Req)" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)
      :ok
    end

    test "GET 200 returns {:ok, body} with parsed JSON map" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:method] == :get
        assert String.ends_with?(opts[:url], "/v2/account")
        {:ok, %Req.Response{status: 200, body: %{"id" => "abc123", "status" => "ACTIVE"}}}
      end)

      assert {:ok, %{"id" => "abc123", "status" => "ACTIVE"}} =
               Client.get("/v2/account", @valid_creds)
    end

    test "GET 200 returns {:ok, body} with list body" do
      body = [%{"symbol" => "AAPL"}, %{"symbol" => "GOOG"}]

      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 200, body: body}}
      end)

      assert {:ok, ^body} = Client.get("/v2/positions", @valid_creds)
    end

    test "204 returns {:ok, :deleted}" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:method] == :delete
        {:ok, %Req.Response{status: 204, body: ""}}
      end)

      assert {:ok, :deleted} = Client.delete("/v2/orders/abc", @valid_creds)
    end

    test "POST 200 returns success with body" do
      order = %{"id" => "order-1", "symbol" => "AAPL", "qty" => "10"}

      :meck.expect(Req, :request, fn opts ->
        assert opts[:method] == :post
        assert opts[:json] == %{symbol: "AAPL", qty: 10}
        {:ok, %Req.Response{status: 200, body: order}}
      end)

      assert {:ok, ^order} =
               Client.post("/v2/orders", %{symbol: "AAPL", qty: 10}, @valid_creds)
    end

    test "PATCH 200 returns success" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:method] == :patch
        {:ok, %Req.Response{status: 200, body: %{"qty" => "20"}}}
      end)

      assert {:ok, %{"qty" => "20"}} =
               Client.patch("/v2/orders/abc", %{qty: 20}, @valid_creds)
    end

    test "PUT 200 returns success" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:method] == :put
        {:ok, %Req.Response{status: 200, body: %{"updated" => true}}}
      end)

      assert {:ok, %{"updated" => true}} =
               Client.put("/v2/watchlists/wl1", %{name: "Favorites"}, @valid_creds)
    end

    test "get_data routes to data API URL" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "data.alpaca.markets"
        {:ok, %Req.Response{status: 200, body: %{"bars" => []}}}
      end)

      assert {:ok, %{"bars" => []}} =
               Client.get_data("/v2/stocks/AAPL/bars", @valid_creds)
    end

    test "GET routes to paper trading URL by default" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "paper-api.alpaca.markets"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end

    test "GET routes to live trading URL when use_paper: false" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "api.alpaca.markets"
        refute opts[:url] =~ "paper"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds ++ [use_paper: false])
    end

    test "201 returns {:ok, body} (any 2xx except 204)" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 201, body: %{"created" => true}}}
      end)

      assert {:ok, %{"created" => true}} = Client.post("/v2/orders", %{}, @valid_creds)
    end
  end

  describe "error HTTP responses (mocked Req)" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)
      :ok
    end

    test "401 response returns unauthorized error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 401, body: %{"message" => "Invalid API key"}}}
      end)

      assert {:error, %Error{type: :unauthorized, message: "Invalid API key"}} =
               Client.get("/v2/account", @valid_creds)
    end

    test "403 response returns forbidden error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 403, body: %{"message" => "Forbidden"}}}
      end)

      assert {:error, %Error{type: :forbidden}} = Client.get("/v2/account", @valid_creds)
    end

    test "404 response returns not_found error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 404, body: %{"message" => "Order not found"}}}
      end)

      assert {:error, %Error{type: :not_found}} = Client.get("/v2/orders/nope", @valid_creds)
    end

    test "422 response returns unprocessable_entity error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok,
         %Req.Response{status: 422, body: %{"message" => "Insufficient qty", "code" => 40_310_000}}}
      end)

      assert {:error, %Error{type: :unprocessable_entity, code: 40_310_000}} =
               Client.post("/v2/orders", %{}, @valid_creds)
    end

    test "429 response returns rate_limited error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 429, body: %{"message" => "Too many requests"}}}
      end)

      assert {:error, %Error{type: :rate_limited}} = Client.get("/v2/account", @valid_creds)
    end

    test "500 response returns server_error" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 500, body: %{"message" => "Internal server error"}}}
      end)

      assert {:error, %Error{type: :server_error}} = Client.get("/v2/account", @valid_creds)
    end

    test "non-JSON string body is handled" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 400, body: "Bad request plain text"}}
      end)

      assert {:error, %Error{type: :unknown, message: "Bad request plain text"}} =
               Client.get("/v2/account", @valid_creds)
    end
  end

  describe "transport and network errors (mocked Req)" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)
      :ok
    end

    test "timeout transport error returns timeout error" do
      :meck.expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :timeout}}
      end)

      assert {:error, %Error{type: :timeout, message: "Request timed out"}} =
               Client.get("/v2/account", @valid_creds)
    end

    test "econnrefused transport error returns network error" do
      :meck.expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :econnrefused}}
      end)

      assert {:error, %Error{type: :network_error}} = Client.get("/v2/account", @valid_creds)

      {:error, err} = Client.get("/v2/account", @valid_creds)
      assert err.message =~ "econnrefused"
    end

    test "nxdomain transport error returns network error" do
      :meck.expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :nxdomain}}
      end)

      {:error, err} = Client.get("/v2/account", @valid_creds)
      assert err.type == :network_error
      assert err.message =~ "nxdomain"
    end

    test "generic exception returns network error" do
      :meck.expect(Req, :request, fn _opts ->
        {:error, %RuntimeError{message: "something broke"}}
      end)

      {:error, err} = Client.get("/v2/account", @valid_creds)
      assert err.type == :network_error
      assert err.message =~ "something broke"
    end
  end

  describe "request construction (mocked Req)" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)
      :ok
    end

    test "auth headers are set with API key and secret" do
      :meck.expect(Req, :request, fn opts ->
        headers = opts[:headers]
        assert {"APCA-API-KEY-ID", "my-key"} in headers
        assert {"APCA-API-SECRET-KEY", "my-secret"} in headers
        assert {"Accept", "application/json"} in headers
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", api_key: "my-key", api_secret: "my-secret")
    end

    test "POST with body sets :json and Content-Type" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:json] == %{symbol: "AAPL", qty: 10}
        headers = opts[:headers]
        assert {"Content-Type", "application/json"} in headers
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.post("/v2/orders", %{symbol: "AAPL", qty: 10}, @valid_creds)
    end

    test "GET without body does NOT set :json key" do
      :meck.expect(Req, :request, fn opts ->
        refute Keyword.has_key?(opts, :json)
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end

    test "params option is forwarded to Req" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:params] == [limit: 50, status: "open"]
        {:ok, %Req.Response{status: 200, body: []}}
      end)

      Client.get("/v2/orders", @valid_creds ++ [params: [limit: 50, status: "open"]])
    end

    test "params are not set when not provided" do
      :meck.expect(Req, :request, fn opts ->
        refute Keyword.has_key?(opts, :params)
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end

    test "custom timeout is forwarded to connect_options" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:connect_options] == [timeout: 5_000]
        assert opts[:receive_timeout] == 10_000
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds ++ [timeout: 5_000, receive_timeout: 10_000])
    end

    test "retry is set to :transient" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:retry] == :transient
        assert is_function(opts[:retry_delay], 1)
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end

    test "POST with nil body does not set :json" do
      :meck.expect(Req, :request, fn opts ->
        refute Keyword.has_key?(opts, :json)
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.post("/v2/some-action", nil, @valid_creds)
    end
  end

  describe "URL routing" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)
      :ok
    end

    test "get uses trading API base URL" do
      :meck.expect(Req, :request, fn opts ->
        refute opts[:url] =~ "data.alpaca.markets"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end

    test "post uses trading API base URL" do
      :meck.expect(Req, :request, fn opts ->
        refute opts[:url] =~ "data.alpaca.markets"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.post("/v2/orders", %{}, @valid_creds)
    end

    test "get_data uses data API base URL" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "data.alpaca.markets"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get_data("/v2/stocks/AAPL/bars", @valid_creds)
    end

    test "custom trading_url is respected" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "https://my-proxy.example.com"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get(
        "/v2/account",
        @valid_creds ++ [trading_url: "https://my-proxy.example.com"]
      )
    end

    test "custom data_url is respected for get_data" do
      :meck.expect(Req, :request, fn opts ->
        assert opts[:url] =~ "https://my-data-proxy.example.com"
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get_data(
        "/v2/stocks/AAPL/bars",
        @valid_creds ++ [data_url: "https://my-data-proxy.example.com"]
      )
    end

    test "path is appended to base URL" do
      :meck.expect(Req, :request, fn opts ->
        assert String.ends_with?(opts[:url], "/v2/account")
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get("/v2/account", @valid_creds)
    end
  end

  describe "telemetry events (mocked Req)" do
    setup do
      :meck.new(Req, [:passthrough])
      on_exit(fn -> try do :meck.unload(Req) rescue _ -> :ok catch _, _ -> :ok end end)

      # Attach telemetry handlers that send messages to the test process
      self_pid = self()

      :telemetry.attach(
        "test-start",
        [:alpa, :request, :start],
        fn event, measurements, metadata, _config ->
          send(self_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      :telemetry.attach(
        "test-stop",
        [:alpa, :request, :stop],
        fn event, measurements, metadata, _config ->
          send(self_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      :telemetry.attach(
        "test-exception",
        [:alpa, :request, :exception],
        fn event, measurements, metadata, _config ->
          send(self_pid, {:telemetry, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach("test-start")
        :telemetry.detach("test-stop")
        :telemetry.detach("test-exception")
      end)

      :ok
    end

    test "emits :start and :stop events on success" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 200, body: %{"ok" => true}}}
      end)

      assert {:ok, _} = Client.get("/v2/account", @valid_creds)

      assert_receive {:telemetry, [:alpa, :request, :start], %{system_time: _}, metadata}
      assert metadata.method == :get
      assert metadata.api == :trading
      assert metadata.path == "/v2/account"

      assert_receive {:telemetry, [:alpa, :request, :stop], %{duration: duration}, _metadata}
      assert is_integer(duration)
    end

    test "emits :start and :exception events on error response" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 500, body: %{"message" => "boom"}}}
      end)

      assert {:error, _} = Client.get("/v2/account", @valid_creds)

      assert_receive {:telemetry, [:alpa, :request, :start], _, _}

      assert_receive {:telemetry, [:alpa, :request, :exception], %{duration: _},
                      %{error: %Error{type: :server_error}}}
    end

    test "emits :exception event on transport error" do
      :meck.expect(Req, :request, fn _opts ->
        {:error, %Req.TransportError{reason: :timeout}}
      end)

      assert {:error, _} = Client.get("/v2/account", @valid_creds)

      assert_receive {:telemetry, [:alpa, :request, :start], _, _}

      assert_receive {:telemetry, [:alpa, :request, :exception], %{duration: _},
                      %{error: %Error{type: :timeout}}}
    end

    test "metadata includes method, api, path, and url" do
      :meck.expect(Req, :request, fn _opts ->
        {:ok, %Req.Response{status: 200, body: %{}}}
      end)

      Client.get_data("/v2/stocks/AAPL/bars", @valid_creds)

      assert_receive {:telemetry, [:alpa, :request, :start], _, metadata}
      assert metadata.method == :get
      assert metadata.api == :data
      assert metadata.path == "/v2/stocks/AAPL/bars"
      assert metadata.url =~ "data.alpaca.markets/v2/stocks/AAPL/bars"
    end

    test "no telemetry events when credentials are missing" do
      Client.get("/v2/account", api_key: nil, api_secret: nil)

      refute_receive {:telemetry, [:alpa, :request, :start], _, _}
    end
  end

  describe "missing credentials for put requests" do
    test "missing credentials for put requests" do
      result = Client.put("/v2/watchlists/wl1", %{name: "Test"}, api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
