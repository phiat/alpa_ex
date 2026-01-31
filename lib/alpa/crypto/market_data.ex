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

  @default_loc "us"

  @doc """
  Get historical bars for a crypto symbol.

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
  Get historical quotes for a crypto symbol.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max quotes to return (default 1000, max 10000)
    * `:page_token` - Pagination token
    * `:loc` - Location (default: "us")

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
  Get historical trades for a crypto symbol.

  ## Required Parameters

    * `symbol` - Crypto symbol (e.g., "BTC/USD")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max trades to return (default 1000, max 10000)
    * `:page_token` - Pagination token
    * `:loc` - Location (default: "us")

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
  Get snapshots for one or more crypto symbols.

  ## Required Parameters

    * `symbols` - A symbol string or list of symbols (e.g., "BTC/USD" or ["BTC/USD", "ETH/USD"])

  ## Options

    * `:loc` - Location (default: "us")

  ## Examples

      iex> Alpa.Crypto.MarketData.get_snapshots("BTC/USD")
      {:ok, %{"snapshots" => ...}}

      iex> Alpa.Crypto.MarketData.get_snapshots(["BTC/USD", "ETH/USD"])
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

  # Private helpers

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
end
