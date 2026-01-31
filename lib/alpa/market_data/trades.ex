defmodule Alpa.MarketData.Trades do
  @moduledoc """
  Trade data from the Alpaca Market Data API v2.
  """

  alias Alpa.Client
  alias Alpa.Models.Trade

  @doc """
  Get historical trades for a single symbol.

  ## Required Parameters

    * `symbol` - Stock symbol (e.g., "AAPL")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max trades to return (default 1000, max 10000)
    * `:feed` - Data feed: "iex", "sip"
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.MarketData.Trades.get("AAPL", start: ~U[2024-01-15 14:30:00Z])
      {:ok, [%Alpa.Models.Trade{...}]}

  """
  @spec get(String.t(), keyword()) :: {:ok, [Trade.t()]} | {:error, Alpa.Error.t()}
  def get(symbol, opts \\ []) do
    params = build_params(opts)
    encoded_symbol = URI.encode_www_form(symbol)

    case Client.get_data(
           "/v2/stocks/#{encoded_symbol}/trades",
           Keyword.put(opts, :params, params)
         ) do
      {:ok, data} -> {:ok, parse_trades(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get historical trades for multiple symbols.

  ## Required Parameters

    * `symbols` - List of stock symbols (e.g., ["AAPL", "MSFT"])

  ## Options

  Same as `get/2`.

  ## Examples

      iex> Alpa.MarketData.Trades.get_multi(["AAPL", "MSFT"], start: ~U[2024-01-15 14:30:00Z])
      {:ok, %{"AAPL" => [%Alpa.Models.Trade{...}], "MSFT" => [%Alpa.Models.Trade{...}]}}

  """
  @spec get_multi([String.t()], keyword()) ::
          {:ok, %{String.t() => [Trade.t()]}} | {:error, Alpa.Error.t()}
  def get_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> build_params()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/trades", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, parse_multi_trades(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the latest trade for a symbol.

  ## Options

    * `:feed` - Data feed: "iex", "sip"

  ## Examples

      iex> Alpa.MarketData.Trades.latest("AAPL")
      {:ok, %Alpa.Models.Trade{...}}

  """
  @spec latest(String.t(), keyword()) :: {:ok, Trade.t()} | {:error, Alpa.Error.t()}
  def latest(symbol, opts \\ []) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    encoded_symbol = URI.encode_www_form(symbol)

    case Client.get_data(
           "/v2/stocks/#{encoded_symbol}/trades/latest",
           Keyword.put(opts, :params, params)
         ) do
      {:ok, %{"trade" => trade}} -> {:ok, Trade.from_map(trade, symbol)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest trades for multiple symbols.

  ## Examples

      iex> Alpa.MarketData.Trades.latest_multi(["AAPL", "MSFT"])
      {:ok, %{"AAPL" => %Alpa.Models.Trade{...}, "MSFT" => %Alpa.Models.Trade{...}}}

  """
  @spec latest_multi([String.t()], keyword()) ::
          {:ok, %{String.t() => Trade.t()}} | {:error, Alpa.Error.t()}
  def latest_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/trades/latest", Keyword.put(opts, :params, params)) do
      {:ok, %{"trades" => trades}} ->
        result =
          Map.new(trades, fn {symbol, trade} -> {symbol, Trade.from_map(trade, symbol)} end)

        {:ok, result}

      {:ok, unexpected} ->
        {:error, Alpa.Error.invalid_response(unexpected)}

      {:error, _} = error ->
        error
    end
  end

  # Private helpers

  defp build_params(opts) do
    opts
    |> Keyword.take([:start, :end, :limit, :feed, :page_token])
    |> Enum.map(fn
      {:start, %DateTime{} = dt} -> {:start, DateTime.to_iso8601(dt)}
      {:end, %DateTime{} = dt} -> {:end, DateTime.to_iso8601(dt)}
      other -> other
    end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_trades(%{"trades" => trades}, symbol) when is_list(trades) do
    Enum.map(trades, &Trade.from_map(&1, symbol))
  end

  defp parse_trades(%{"trades" => nil}, _symbol), do: []
  defp parse_trades(_, _symbol), do: []

  defp parse_multi_trades(%{"trades" => trades}) when is_map(trades) do
    Map.new(trades, fn {symbol, trade_list} ->
      {symbol, Enum.map(trade_list, &Trade.from_map(&1, symbol))}
    end)
  end

  defp parse_multi_trades(%{"trades" => nil}), do: %{}
  defp parse_multi_trades(_), do: %{}
end
