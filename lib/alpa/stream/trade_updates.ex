defmodule Alpa.Stream.TradeUpdates do
  @moduledoc """
  WebSocket stream for real-time trade updates from the Alpaca Trading API.

  This module provides a GenServer-based WebSocket client that streams
  order fills, partial fills, cancellations, and other trade events.

  ## Usage

      # Start the stream with a callback function
      {:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
        callback: fn event -> IO.inspect(event, label: "Trade Update") end
      )

      # Or use a module callback
      {:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
        callback: {MyModule, :handle_trade_update, []}
      )

      # Stop the stream
      Alpa.Stream.TradeUpdates.stop(pid)

  ## Events

  Trade update events include:
  - `new` - Order has been received
  - `fill` - Order has been completely filled
  - `partial_fill` - Order has been partially filled
  - `canceled` - Order has been canceled
  - `expired` - Order has expired
  - `replaced` - Order has been replaced
  - `rejected` - Order has been rejected
  - `pending_new` - Order is pending acceptance
  - `pending_cancel` - Order cancellation is pending
  - `pending_replace` - Order replacement is pending
  """

  use WebSockex
  require Logger
  import Alpa.Helpers, only: [parse_decimal: 1, parse_datetime: 1]

  alias Alpa.Config
  alias Alpa.Models.Order

  @paper_stream_url "wss://paper-api.alpaca.markets/stream"
  @live_stream_url "wss://api.alpaca.markets/stream"

  @max_reconnect_ms 60_000
  @initial_backoff_ms 1_000
  @jitter_min 0.5
  @jitter_max 1.5
  @default_max_reconnect_attempts 50

  defstruct [
    :callback,
    :config,
    :authenticated,
    :connection_status,
    reconnect_attempts: 0,
    max_reconnect_attempts: @default_max_reconnect_attempts,
    consecutive_callback_errors: 0
  ]

  @type callback :: (map() -> any()) | {module(), atom(), list()}

  @doc """
  Start the trade updates WebSocket stream.

  ## Options

    * `:callback` - Required. Function or MFA tuple to handle trade update events
    * `:api_key` - API key (uses config if not provided)
    * `:api_secret` - API secret (uses config if not provided)
    * `:use_paper` - Use paper trading endpoint (default: true)
    * `:name` - Optional GenServer name for the process

  ## Examples

      # With anonymous function
      {:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
        callback: fn event -> process_event(event) end
      )

      # With MFA tuple
      {:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
        callback: {MyHandler, :handle_event, [extra_arg]}
      )

  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    callback = Keyword.fetch!(opts, :callback)
    config = Config.new(opts)

    max_reconnect = Keyword.get(opts, :max_reconnect_attempts, @default_max_reconnect_attempts)

    if Config.has_credentials?(config) do
      url = if config.use_paper, do: @paper_stream_url, else: @live_stream_url

      state = %__MODULE__{
        callback: callback,
        config: config,
        authenticated: false,
        connection_status: :connecting,
        reconnect_attempts: 0,
        max_reconnect_attempts: max_reconnect,
        consecutive_callback_errors: 0
      }

      ws_opts =
        case Keyword.get(opts, :name) do
          nil -> []
          name -> [name: name]
        end

      WebSockex.start_link(url, __MODULE__, state, ws_opts)
    else
      {:error, :missing_credentials}
    end
  end

  @doc """
  Stop the trade updates stream.
  """
  @spec stop(pid()) :: :ok
  def stop(pid) do
    WebSockex.cast(pid, :close)
  end

  @doc """
  Returns the current connection status.

  Possible values: `:connected`, `:disconnected`, `:connecting`
  """
  @spec connection_status(pid()) :: :connected | :disconnected | :connecting
  def connection_status(pid) do
    try do
      state = :sys.get_state(pid)
      state.connection_status
    rescue
      _ -> :disconnected
    catch
      :exit, _ -> :disconnected
    end
  end

  # WebSockex Callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.debug("[TradeUpdates] Connected to WebSocket")
    send(self(), :authenticate)
    {:ok, %{state | connection_status: :connecting}}
  end

  @impl WebSockex
  def handle_info(:authenticate, state) do
    auth_msg =
      Jason.encode!(%{
        action: "auth",
        key: state.config.api_key,
        secret: state.config.api_secret
      })

    {:reply, {:text, auth_msg}, state}
  end

  @impl WebSockex
  def handle_info(:subscribe, state) do
    subscribe_msg =
      Jason.encode!(%{
        action: "listen",
        data: %{streams: ["trade_updates"]}
      })

    {:reply, {:text, subscribe_msg}, state}
  end

  @impl WebSockex
  def handle_info(:reconnect, state) do
    {:reconnect, %{state | connection_status: :connecting}}
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"stream" => "authorization", "data" => %{"status" => "authorized"}}} ->
        Logger.info("[TradeUpdates] Authenticated successfully")
        send(self(), :subscribe)
        redacted_config = %{state.config | api_key: :redacted, api_secret: :redacted}

        {:ok,
         %{
           state
           | authenticated: true,
             connection_status: :connected,
             reconnect_attempts: 0,
             config: redacted_config
         }}

      {:ok, %{"stream" => "authorization", "data" => %{"status" => status}}} ->
        Logger.error("[TradeUpdates] Authentication failed: #{status}")
        {:close, state}

      {:ok, %{"stream" => "listening", "data" => %{"streams" => streams}}} ->
        Logger.info("[TradeUpdates] Subscribed to: #{inspect(streams)}")
        {:ok, state}

      {:ok, %{"stream" => "trade_updates", "data" => data}} ->
        state = handle_trade_update(data, state)
        {:ok, state}

      {:ok, data} ->
        Logger.debug("[TradeUpdates] Received: #{inspect(data)}")
        {:ok, state}

      {:error, reason} ->
        Logger.warning("[TradeUpdates] Failed to parse message: #{reason}")
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_frame({:ping, _}, state) do
    {:reply, {:pong, ""}, state}
  end

  @impl WebSockex
  def handle_frame(frame, state) do
    Logger.debug("[TradeUpdates] Received frame: #{inspect(frame)}")
    {:ok, state}
  end

  @impl WebSockex
  def handle_cast(:close, state) do
    {:close, state}
  end

  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("[TradeUpdates] Disconnected: #{inspect(reason)}")

    new_attempts = state.reconnect_attempts + 1

    if new_attempts >= state.max_reconnect_attempts do
      Logger.warning(
        "[TradeUpdates] Max reconnect attempts (#{state.max_reconnect_attempts}) reached, giving up"
      )

      {:ok,
       %{
         state
         | authenticated: false,
           connection_status: :disconnected,
           reconnect_attempts: new_attempts
       }}
    else
      delay = reconnect_delay(new_attempts)
      Logger.info("[TradeUpdates] Reconnecting in #{delay}ms (attempt #{new_attempts})")
      Process.send_after(self(), :reconnect, delay)

      {:ok,
       %{
         state
         | authenticated: false,
           connection_status: :disconnected,
           reconnect_attempts: new_attempts
       }}
    end
  end

  @impl WebSockex
  def terminate(reason, _state) do
    Logger.info("[TradeUpdates] Terminated: #{inspect(reason)}")
    :ok
  end

  # Private helpers

  defp reconnect_delay(attempts) do
    base = min(@initial_backoff_ms * Integer.pow(2, attempts - 1), @max_reconnect_ms)
    jitter_factor = @jitter_min + :rand.uniform() * (@jitter_max - @jitter_min)
    trunc(base * jitter_factor)
  end

  defp handle_trade_update(data, state) do
    event = parse_trade_event(data)

    try do
      case state.callback do
        fun when is_function(fun, 1) ->
          fun.(event)

        {mod, fun, args} ->
          apply(mod, fun, [event | args])
      end

      %{state | consecutive_callback_errors: 0}
    rescue
      error ->
        new_count = state.consecutive_callback_errors + 1

        if new_count >= 10 do
          Logger.error(
            "[TradeUpdates] #{new_count} consecutive callback errors, latest: #{inspect(error)}"
          )
        else
          Logger.error("[TradeUpdates] Callback error: #{inspect(error)}")
        end

        %{state | consecutive_callback_errors: new_count}
    end
  end

  defp parse_trade_event(data) do
    %{
      event: data["event"],
      timestamp: parse_datetime(data["timestamp"]),
      order: parse_order(data["order"]),
      execution_id: data["execution_id"],
      position_qty: parse_decimal(data["position_qty"]),
      price: parse_decimal(data["price"]),
      qty: parse_decimal(data["qty"])
    }
  end

  defp parse_order(nil), do: nil

  defp parse_order(order) do
    Order.from_map(order)
  end
end
