defmodule Alpa.Client do
  @moduledoc """
  HTTP client for the Alpaca API.

  Uses Req for HTTP requests with automatic:
  - Authentication header injection
  - JSON encoding/decoding
  - Error handling
  - Retry logic for rate limiting
  """

  alias Alpa.{Config, Error}

  @type response :: {:ok, map() | [map()] | :deleted} | {:error, Error.t()}

  @doc """
  Make a GET request to the trading API.
  """
  @spec get(String.t(), keyword()) :: response()
  def get(path, opts \\ []) do
    request(:get, :trading, path, nil, opts)
  end

  @doc """
  Make a POST request to the trading API.
  """
  @spec post(String.t(), map() | nil, keyword()) :: response()
  def post(path, body \\ nil, opts \\ []) do
    request(:post, :trading, path, body, opts)
  end

  @doc """
  Make a PATCH request to the trading API.
  """
  @spec patch(String.t(), map(), keyword()) :: response()
  def patch(path, body, opts \\ []) do
    request(:patch, :trading, path, body, opts)
  end

  @doc """
  Make a PUT request to the trading API.
  """
  @spec put(String.t(), map(), keyword()) :: response()
  def put(path, body, opts \\ []) do
    request(:put, :trading, path, body, opts)
  end

  @doc """
  Make a DELETE request to the trading API.
  """
  @spec delete(String.t(), keyword()) :: response()
  def delete(path, opts \\ []) do
    request(:delete, :trading, path, nil, opts)
  end

  @doc """
  Make a GET request to the market data API.
  """
  @spec get_data(String.t(), keyword()) :: response()
  def get_data(path, opts \\ []) do
    request(:get, :data, path, nil, opts)
  end

  @doc """
  Make a request with explicit config.
  """
  @spec request(atom(), :trading | :data, String.t(), map() | nil, keyword()) :: response()
  def request(method, api, path, body, opts) do
    config = Config.new(opts)

    if Config.has_credentials?(config) do
      base_url = get_base_url(api, config)
      url = base_url <> path
      metadata = %{method: method, api: api, path: path, url: url}

      req_opts =
        [
          method: method,
          url: url,
          headers: auth_headers(config),
          connect_options: [timeout: config.timeout],
          receive_timeout: config.receive_timeout,
          retry: :transient,
          retry_delay: &retry_delay/1
        ]
        |> maybe_add_body(body)
        |> maybe_add_params(opts)

      execute_with_telemetry(req_opts, metadata)
    else
      {:error, Error.missing_credentials()}
    end
  end

  defp execute_with_telemetry(req_opts, metadata) do
    start_time = System.monotonic_time()
    :telemetry.execute([:alpa, :request, :start], %{system_time: System.system_time()}, metadata)

    result = do_request(req_opts)
    duration = System.monotonic_time() - start_time
    emit_telemetry_stop(result, duration, metadata)
    result
  end

  defp do_request(req_opts) do
    case Req.request(req_opts) do
      {:ok, %Req.Response{status: 204}} ->
        {:ok, :deleted}

      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, Error.from_response(status, body)}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, Error.timeout_error()}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, Error.network_error(reason)}

      {:error, exception} ->
        {:error, Error.network_error(exception)}
    end
  end

  defp emit_telemetry_stop({:ok, _}, duration, metadata) do
    :telemetry.execute([:alpa, :request, :stop], %{duration: duration}, metadata)
  end

  defp emit_telemetry_stop({:error, error}, duration, metadata) do
    :telemetry.execute(
      [:alpa, :request, :exception],
      %{duration: duration},
      Map.put(metadata, :error, error)
    )
  end

  # Private helpers

  defp get_base_url(:trading, config), do: Config.trading_url(config)
  defp get_base_url(:data, config), do: Config.data_url(config)

  defp auth_headers(%Config{api_key: key, api_secret: secret}) do
    [
      {"APCA-API-KEY-ID", key},
      {"APCA-API-SECRET-KEY", secret},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end

  defp maybe_add_body(opts, nil), do: opts
  defp maybe_add_body(opts, body), do: Keyword.put(opts, :json, body)

  defp maybe_add_params(opts, keyword_opts) do
    params = Keyword.get(keyword_opts, :params)
    if params, do: Keyword.put(opts, :params, params), else: opts
  end

  # Exponential backoff for rate limiting
  defp retry_delay(n) do
    # 1s, 2s, 4s, 8s, 16s max
    delay = min(:timer.seconds(1) * Integer.pow(2, n - 1), :timer.seconds(16))
    delay + :rand.uniform(1000)
  end
end
