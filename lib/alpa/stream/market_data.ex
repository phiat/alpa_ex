defmodule Alpa.Stream.MarketData do
  @moduledoc """
  WebSocket stream for real-time market data from the Alpaca Market Data API.

  This module provides a GenServer-based WebSocket client that streams
  real-time trades, quotes, and bars for subscribed symbols.

  ## Usage

      # Start the stream
      {:ok, pid} = Alpa.Stream.MarketData.start_link(
        callback: fn event -> IO.inspect(event, label: "Market Data") end
      )

      # Subscribe to symbols
      Alpa.Stream.MarketData.subscribe(pid, trades: ["AAPL", "MSFT"])
      Alpa.Stream.MarketData.subscribe(pid, quotes: ["AAPL"], bars: ["SPY"])

      # Unsubscribe
      Alpa.Stream.MarketData.unsubscribe(pid, trades: ["MSFT"])

      # Stop the stream
      Alpa.Stream.MarketData.stop(pid)

  ## Event Types

  Events have a `:type` field indicating the data type:
  - `:trade` - Real-time trade data
  - `:quote` - Real-time quote (NBBO) data
  - `:bar` - Real-time minute bar data

  ## Feeds

  Available feeds:
  - `"iex"` - IEX exchange data (free)
  - `"sip"` - All US exchanges (requires subscription)
  """

  use WebSockex
  require Logger

  alias Alpa.Config
  alias Alpa.Models.{Bar, Quote, Trade}

  @iex_stream_url "wss://stream.data.alpaca.markets/v2/iex"
  @sip_stream_url "wss://stream.data.alpaca.markets/v2/sip"

  defstruct [:callback, :config, :authenticated, :subscriptions]

  @type callback :: (map() -> any()) | {module(), atom(), list()}
  @type subscription_type :: :trades | :quotes | :bars

  @doc """
  Start the market data WebSocket stream.

  ## Options

    * `:callback` - Required. Function or MFA tuple to handle market data events
    * `:feed` - Data feed: "iex" (default) or "sip"
    * `:api_key` - API key (uses config if not provided)
    * `:api_secret` - API secret (uses config if not provided)
    * `:name` - Optional GenServer name for the process

  ## Examples

      {:ok, pid} = Alpa.Stream.MarketData.start_link(
        callback: fn event -> process_event(event) end,
        feed: "iex"
      )

  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    callback = Keyword.fetch!(opts, :callback)
    config = Config.new(opts)
    feed = Keyword.get(opts, :feed, "iex")

    if Config.has_credentials?(config) do
      url = if feed == "sip", do: @sip_stream_url, else: @iex_stream_url

      state = %__MODULE__{
        callback: callback,
        config: config,
        authenticated: false,
        subscriptions: %{trades: [], quotes: [], bars: []}
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
  Subscribe to market data for symbols.

  ## Options

    * `:trades` - List of symbols to subscribe for trades
    * `:quotes` - List of symbols to subscribe for quotes
    * `:bars` - List of symbols to subscribe for minute bars

  ## Examples

      Alpa.Stream.MarketData.subscribe(pid, trades: ["AAPL", "MSFT"], quotes: ["AAPL"])

  """
  @spec subscribe(pid(), keyword()) :: :ok
  def subscribe(pid, subscriptions) do
    WebSockex.cast(pid, {:subscribe, subscriptions})
  end

  @doc """
  Unsubscribe from market data for symbols.

  ## Examples

      Alpa.Stream.MarketData.unsubscribe(pid, trades: ["MSFT"])

  """
  @spec unsubscribe(pid(), keyword()) :: :ok
  def unsubscribe(pid, subscriptions) do
    WebSockex.cast(pid, {:unsubscribe, subscriptions})
  end

  @doc """
  Stop the market data stream.
  """
  @spec stop(pid()) :: :ok
  def stop(pid) do
    WebSockex.cast(pid, :close)
  end

  # WebSockex Callbacks

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.debug("[MarketData] Connected to WebSocket")
    send(self(), :authenticate)
    {:ok, state}
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
  def handle_info(:reconnect, state) do
    {:reconnect, state}
  end

  @impl WebSockex
  def handle_info(:resubscribe, state) do
    if state.authenticated and has_subscriptions?(state.subscriptions) do
      msg =
        Jason.encode!(%{
          action: "subscribe",
          trades: state.subscriptions.trades,
          quotes: state.subscriptions.quotes,
          bars: state.subscriptions.bars
        })

      {:reply, {:text, msg}, state}
    else
      # Not authenticated yet, try again in 1 second
      Process.send_after(self(), :resubscribe, 1000)
      {:ok, state}
    end
  end

  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, messages} when is_list(messages) ->
        state = Enum.reduce(messages, state, &handle_message/2)
        {:ok, state}

      {:ok, message} when is_map(message) ->
        state = handle_message(message, state)
        {:ok, state}

      {:error, reason} ->
        Logger.warning("[MarketData] Failed to parse message: #{reason}")
        {:ok, state}
    end
  end

  @impl WebSockex
  def handle_frame({:ping, _}, state) do
    {:reply, :pong, state}
  end

  @impl WebSockex
  def handle_frame(frame, state) do
    Logger.debug("[MarketData] Received frame: #{inspect(frame)}")
    {:ok, state}
  end

  @impl WebSockex
  def handle_cast({:subscribe, subscriptions}, state) do
    msg =
      Jason.encode!(%{
        action: "subscribe",
        trades: Keyword.get(subscriptions, :trades, []),
        quotes: Keyword.get(subscriptions, :quotes, []),
        bars: Keyword.get(subscriptions, :bars, [])
      })

    new_subs = merge_subscriptions(state.subscriptions, subscriptions)
    {:reply, {:text, msg}, %{state | subscriptions: new_subs}}
  end

  @impl WebSockex
  def handle_cast({:unsubscribe, subscriptions}, state) do
    msg =
      Jason.encode!(%{
        action: "unsubscribe",
        trades: Keyword.get(subscriptions, :trades, []),
        quotes: Keyword.get(subscriptions, :quotes, []),
        bars: Keyword.get(subscriptions, :bars, [])
      })

    new_subs = remove_subscriptions(state.subscriptions, subscriptions)
    {:reply, {:text, msg}, %{state | subscriptions: new_subs}}
  end

  @impl WebSockex
  def handle_cast(:close, state) do
    {:close, state}
  end

  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("[MarketData] Disconnected: #{inspect(reason)}")
    # Schedule non-blocking reconnect after 5 seconds
    Process.send_after(self(), :reconnect, 5000)
    {:ok, %{state | authenticated: false}}
  end

  @impl WebSockex
  def terminate(reason, _state) do
    Logger.info("[MarketData] Terminated: #{inspect(reason)}")
    :ok
  end

  # Message handlers

  defp handle_message(%{"T" => "success", "msg" => "connected"}, state) do
    Logger.debug("[MarketData] Connected message received")
    state
  end

  defp handle_message(%{"T" => "success", "msg" => "authenticated"}, state) do
    Logger.info("[MarketData] Authenticated successfully")

    # Resubscribe if we have existing subscriptions (reconnection case)
    if has_subscriptions?(state.subscriptions) do
      send(self(), :resubscribe)
    end

    %{state | authenticated: true}
  end

  defp handle_message(%{"T" => "error", "code" => code, "msg" => msg}, state) do
    Logger.error("[MarketData] Error #{code}: #{msg}")
    state
  end

  defp handle_message(%{"T" => "subscription"} = msg, state) do
    Logger.info("[MarketData] Subscription updated: trades=#{length(msg["trades"] || [])}, quotes=#{length(msg["quotes"] || [])}, bars=#{length(msg["bars"] || [])}")
    state
  end

  defp handle_message(%{"T" => "t"} = data, state) do
    # Trade
    event = %{type: :trade, data: Trade.from_map(data)}
    invoke_callback(event, state)
    state
  end

  defp handle_message(%{"T" => "q"} = data, state) do
    # Quote
    event = %{type: :quote, data: Quote.from_map(data)}
    invoke_callback(event, state)
    state
  end

  defp handle_message(%{"T" => "b"} = data, state) do
    # Bar
    event = %{type: :bar, data: Bar.from_map(data)}
    invoke_callback(event, state)
    state
  end

  defp handle_message(msg, state) do
    Logger.debug("[MarketData] Unhandled message: #{inspect(msg)}")
    state
  end

  # Private helpers

  defp invoke_callback(event, state) do
    case state.callback do
      fun when is_function(fun, 1) ->
        fun.(event)

      {mod, fun, args} ->
        apply(mod, fun, [event | args])
    end
  rescue
    error ->
      Logger.error("[MarketData] Callback error: #{inspect(error)}")
  end

  defp merge_subscriptions(current, new) do
    %{
      trades: Enum.uniq(current.trades ++ Keyword.get(new, :trades, [])),
      quotes: Enum.uniq(current.quotes ++ Keyword.get(new, :quotes, [])),
      bars: Enum.uniq(current.bars ++ Keyword.get(new, :bars, []))
    }
  end

  defp remove_subscriptions(current, to_remove) do
    %{
      trades: current.trades -- Keyword.get(to_remove, :trades, []),
      quotes: current.quotes -- Keyword.get(to_remove, :quotes, []),
      bars: current.bars -- Keyword.get(to_remove, :bars, [])
    }
  end

  defp has_subscriptions?(subs) do
    subs.trades != [] or subs.quotes != [] or subs.bars != []
  end
end
