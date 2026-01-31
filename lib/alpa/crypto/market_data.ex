defmodule Alpa.Crypto.MarketData do
  @moduledoc """
  Cryptocurrency market data from the Alpaca Crypto Market Data API v1beta3.

  Provides access to crypto bars, quotes, trades, snapshots, and orderbooks.

  All endpoints use the `data.alpaca.markets/v1beta3/crypto/{loc}/` base path,
  where `{loc}` defaults to `"us"`.

  ## Options

  All functions accept an `:loc` option to specify the location (default: `"us"`).
  """

  alias Alpa.Client
  alias Alpa.Models.{Bar, Quote, Trade, Snapshot}

  @default_loc "us"

  # ============================================================================
  # Bars
  # ============================================================================

  @doc """
  Get historical bars for a crypto symbol.

  Returns parsed `Alpa.Models.Bar` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:timeframe` - Bar timeframe: "1Min", "5Min", "15Min", "30Min", "1Hour", "4Hour", "1Day", "1Week", "1Month"
    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max bars to return (default 1000, max 10000)
    * `:page_token` - Pagination token
    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.bars("BTC/USD", timeframe: "1Day", limit: 10)
      {:ok, [%Alpa.Models.Bar{symbol: "BTC/USD", ...}]}

  """
  @spec bars(String.t(), keyword()) :: {:ok, [Bar.t()]} | {:error, Alpa.Error.t()}
  def bars(symbol, opts \\ []) do
    case get_bars(symbol, opts) do
      {:ok, data} -> {:ok, parse_bars(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest bars for a crypto symbol.

  Returns parsed `Alpa.Models.Bar` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.latest_bars("BTC/USD")
      {:ok, [%Alpa.Models.Bar{symbol: "BTC/USD", ...}]}

  """
  @spec latest_bars(String.t(), keyword()) :: {:ok, [Bar.t()]} | {:error, Alpa.Error.t()}
  def latest_bars(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params = %{symbols: symbol}

    case Client.get_data(
           "/v1beta3/crypto/#{loc}/latest/bars",
           Keyword.put(opts, :params, params)
         ) do
      {:ok, data} -> {:ok, parse_bars(data, symbol)}
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Quotes
  # ============================================================================

  @doc """
  Get historical quotes for a crypto symbol.

  Returns parsed `Alpa.Models.Quote` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max quotes to return (default 1000, max 10000)
    * `:page_token` - Pagination token
    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.quotes("BTC/USD", limit: 10)
      {:ok, [%Alpa.Models.Quote{symbol: "BTC/USD", ...}]}

  """
  @spec quotes(String.t(), keyword()) :: {:ok, [Quote.t()]} | {:error, Alpa.Error.t()}
  def quotes(symbol, opts \\ []) do
    case get_quotes(symbol, opts) do
      {:ok, data} -> {:ok, parse_quotes(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest quotes for a crypto symbol.

  Returns parsed `Alpa.Models.Quote` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.latest_quotes("BTC/USD")
      {:ok, [%Alpa.Models.Quote{symbol: "BTC/USD", ...}]}

  """
  @spec latest_quotes(String.t(), keyword()) :: {:ok, [Quote.t()]} | {:error, Alpa.Error.t()}
  def latest_quotes(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params = %{symbols: symbol}

    case Client.get_data(
           "/v1beta3/crypto/#{loc}/latest/quotes",
           Keyword.put(opts, :params, params)
         ) do
      {:ok, data} -> {:ok, parse_quotes(data, symbol)}
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Trades
  # ============================================================================

  @doc """
  Get historical trades for a crypto symbol.

  Returns parsed `Alpa.Models.Trade` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max trades to return (default 1000, max 10000)
    * `:page_token` - Pagination token
    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.trades("BTC/USD", limit: 10)
      {:ok, [%Alpa.Models.Trade{symbol: "BTC/USD", ...}]}

  """
  @spec trades(String.t(), keyword()) :: {:ok, [Trade.t()]} | {:error, Alpa.Error.t()}
  def trades(symbol, opts \\ []) do
    case get_trades(symbol, opts) do
      {:ok, data} -> {:ok, parse_trades(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest trades for a crypto symbol.

  Returns parsed `Alpa.Models.Trade` structs.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.latest_trades("BTC/USD")
      {:ok, [%Alpa.Models.Trade{symbol: "BTC/USD", ...}]}

  """
  @spec latest_trades(String.t(), keyword()) :: {:ok, [Trade.t()]} | {:error, Alpa.Error.t()}
  def latest_trades(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params = %{symbols: symbol}

    case Client.get_data(
           "/v1beta3/crypto/#{loc}/latest/trades",
           Keyword.put(opts, :params, params)
         ) do
      {:ok, data} -> {:ok, parse_trades(data, symbol)}
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Snapshots
  # ============================================================================

  @doc """
  Get snapshots for one or more crypto symbols.

  Returns parsed `Alpa.Models.Snapshot` structs.

  ## Required Parameters

    * `symbols` - A symbol string or list of symbols (e.g., "BTC/USD" or ["BTC/USD", "ETH/USD"])

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.snapshots("BTC/USD")
      {:ok, %{"BTC/USD" => %Alpa.Models.Snapshot{...}}}

      iex> Alpa.Crypto.MarketData.snapshots(["BTC/USD", "ETH/USD"])
      {:ok, %{"BTC/USD" => %Alpa.Models.Snapshot{...}, "ETH/USD" => %Alpa.Models.Snapshot{...}}}

  """
  @spec snapshots(String.t() | [String.t()], keyword()) ::
          {:ok, %{String.t() => Snapshot.t()}} | {:error, Alpa.Error.t()}
  def snapshots(symbols, opts \\ []) do
    case get_snapshots(symbols, opts) do
      {:ok, data} -> {:ok, parse_snapshots(data)}
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Raw API functions (return unparsed maps)
  # ============================================================================

  @doc """
  Get historical bars for a crypto symbol (raw response).

  ## Examples

      iex> Alpa.Crypto.MarketData.get_bars("BTC/USD", timeframe: "1Day", limit: 10)
      {:ok, %{"bars" => ...}}

  """
  @spec get_bars(String.t(), keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_bars(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params =
      opts
      |> build_params([:symbols, :timeframe, :start, :end, :limit, :page_token])
      |> Map.put(:symbols, symbol)

    Client.get_data(
      "/v1beta3/crypto/#{loc}/bars",
      Keyword.put(opts, :params, params)
    )
  end

  @doc """
  Get historical quotes for a crypto symbol (raw response).

  ## Examples

      iex> Alpa.Crypto.MarketData.get_quotes("BTC/USD", limit: 10)
      {:ok, %{"quotes" => ...}}

  """
  @spec get_quotes(String.t(), keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_quotes(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params =
      opts
      |> build_params([:symbols, :start, :end, :limit, :page_token])
      |> Map.put(:symbols, symbol)

    Client.get_data(
      "/v1beta3/crypto/#{loc}/quotes",
      Keyword.put(opts, :params, params)
    )
  end

  @doc """
  Get historical trades for a crypto symbol (raw response).

  ## Examples

      iex> Alpa.Crypto.MarketData.get_trades("BTC/USD", limit: 10)
      {:ok, %{"trades" => ...}}

  """
  @spec get_trades(String.t(), keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_trades(symbol, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    params =
      opts
      |> build_params([:symbols, :start, :end, :limit, :page_token])
      |> Map.put(:symbols, symbol)

    Client.get_data(
      "/v1beta3/crypto/#{loc}/trades",
      Keyword.put(opts, :params, params)
    )
  end

  @doc """
  Get snapshots for one or more crypto symbols (raw response).

  ## Examples

      iex> Alpa.Crypto.MarketData.get_snapshots("BTC/USD")
      {:ok, %{"snapshots" => ...}}

  """
  @spec get_snapshots(String.t() | [String.t()], keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_snapshots(symbols, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    symbols_str =
      case symbols do
        list when is_list(list) -> Enum.join(list, ",")
        str when is_binary(str) -> str
      end

    params = %{symbols: symbols_str}

    Client.get_data(
      "/v1beta3/crypto/#{loc}/snapshots",
      Keyword.put(opts, :params, params)
    )
  end

  @doc """
  Get orderbooks for one or more crypto symbols.

  ## Required Parameters

    * `symbols` - A symbol string or list of symbols (e.g., "BTC/USD" or ["BTC/USD", "ETH/USD"])

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.get_orderbook("BTC/USD")
      {:ok, %{"orderbooks" => ...}}

      iex> Alpa.Crypto.MarketData.get_orderbook(["BTC/USD", "ETH/USD"])
      {:ok, %{"orderbooks" => ...}}

  """
  @spec get_orderbook(String.t() | [String.t()], keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_orderbook(symbols, opts \\ []) do
    {loc, opts} = Keyword.pop(opts, :loc, @default_loc)

    symbols_str =
      case symbols do
        list when is_list(list) -> Enum.join(list, ",")
        str when is_binary(str) -> str
      end

    params = %{symbols: symbols_str}

    Client.get_data(
      "/v1beta3/crypto/#{loc}/orderbooks",
      Keyword.put(opts, :params, params)
    )
  end

  # ============================================================================
  # Private helpers
  # ============================================================================

  defp build_params(opts, keys) do
    opts
    |> Keyword.take(keys)
    |> Enum.map(fn
      {:start, %DateTime{} = dt} -> {:start, DateTime.to_iso8601(dt)}
      {:end, %DateTime{} = dt} -> {:end, DateTime.to_iso8601(dt)}
      other -> other
    end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_bars(%{"bars" => bars}, symbol) when is_map(bars) do
    case Map.get(bars, symbol) do
      nil -> []
      bar_list when is_list(bar_list) -> Enum.map(bar_list, &Bar.from_map(&1, symbol))
      bar when is_map(bar) -> [Bar.from_map(bar, symbol)]
    end
  end

  defp parse_bars(%{"bars" => nil}, _symbol), do: []
  defp parse_bars(_, _symbol), do: []

  defp parse_quotes(%{"quotes" => quotes}, symbol) when is_map(quotes) do
    case Map.get(quotes, symbol) do
      nil -> []
      quote_list when is_list(quote_list) -> Enum.map(quote_list, &Quote.from_map(&1, symbol))
      quote when is_map(quote) -> [Quote.from_map(quote, symbol)]
    end
  end

  defp parse_quotes(%{"quotes" => nil}, _symbol), do: []
  defp parse_quotes(_, _symbol), do: []

  defp parse_trades(%{"trades" => trades}, symbol) when is_map(trades) do
    case Map.get(trades, symbol) do
      nil -> []
      trade_list when is_list(trade_list) -> Enum.map(trade_list, &Trade.from_map(&1, symbol))
      trade when is_map(trade) -> [Trade.from_map(trade, symbol)]
    end
  end

  defp parse_trades(%{"trades" => nil}, _symbol), do: []
  defp parse_trades(_, _symbol), do: []

  defp parse_snapshots(%{"snapshots" => snapshots}) when is_map(snapshots) do
    Map.new(snapshots, fn {symbol, data} ->
      {symbol, Snapshot.from_map(data, symbol)}
    end)
  end

  defp parse_snapshots(%{"snapshots" => nil}), do: %{}
  defp parse_snapshots(_), do: %{}
end
