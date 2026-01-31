defmodule Alpa.MarketData.Bars do
  @moduledoc """
  Historical bar (OHLCV) data from the Alpaca Market Data API v2.
  """

  alias Alpa.Client
  alias Alpa.Models.Bar

  @doc """
  Get historical bars for a single symbol.

  ## Required Parameters

    * `symbol` - Stock symbol (e.g., "AAPL")

  ## Options

    * `:timeframe` - Bar timeframe: "1Min", "5Min", "15Min", "30Min", "1Hour", "4Hour", "1Day", "1Week", "1Month"
    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max bars to return (default 1000, max 10000)
    * `:adjustment` - Price adjustment: "raw", "split", "dividend", "all" (default: "raw")
    * `:feed` - Data feed: "iex", "sip" (default depends on subscription)
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.MarketData.Bars.get("AAPL", timeframe: "1Day", start: ~U[2024-01-01 00:00:00Z])
      {:ok, [%Alpa.Models.Bar{...}]}

  """
  @spec get(String.t(), keyword()) :: {:ok, [Bar.t()]} | {:error, Alpa.Error.t()}
  def get(symbol, opts \\ []) do
    params = build_params(opts)
    encoded_symbol = URI.encode_www_form(symbol)

    case Client.get_data("/v2/stocks/#{encoded_symbol}/bars", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, parse_bars(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get historical bars for multiple symbols.

  ## Required Parameters

    * `symbols` - List of stock symbols (e.g., ["AAPL", "MSFT", "GOOGL"])

  ## Options

  Same as `get/2`.

  ## Examples

      iex> Alpa.MarketData.Bars.get_multi(["AAPL", "MSFT"], timeframe: "1Day", start: ~U[2024-01-01 00:00:00Z])
      {:ok, %{"AAPL" => [%Alpa.Models.Bar{...}], "MSFT" => [%Alpa.Models.Bar{...}]}}

  """
  @spec get_multi([String.t()], keyword()) :: {:ok, %{String.t() => [Bar.t()]}} | {:error, Alpa.Error.t()}
  def get_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> build_params()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/bars", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, parse_multi_bars(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the latest bar for a symbol.

  ## Options

    * `:feed` - Data feed: "iex", "sip"

  ## Examples

      iex> Alpa.MarketData.Bars.latest("AAPL")
      {:ok, %Alpa.Models.Bar{...}}

  """
  @spec latest(String.t(), keyword()) :: {:ok, Bar.t()} | {:error, Alpa.Error.t()}
  def latest(symbol, opts \\ []) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    encoded_symbol = URI.encode_www_form(symbol)

    case Client.get_data("/v2/stocks/#{encoded_symbol}/bars/latest", Keyword.put(opts, :params, params)) do
      {:ok, %{"bar" => bar}} -> {:ok, Bar.from_map(bar, symbol)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest bars for multiple symbols.

  ## Examples

      iex> Alpa.MarketData.Bars.latest_multi(["AAPL", "MSFT"])
      {:ok, %{"AAPL" => %Alpa.Models.Bar{...}, "MSFT" => %Alpa.Models.Bar{...}}}

  """
  @spec latest_multi([String.t()], keyword()) :: {:ok, %{String.t() => Bar.t()}} | {:error, Alpa.Error.t()}
  def latest_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/bars/latest", Keyword.put(opts, :params, params)) do
      {:ok, %{"bars" => bars}} ->
        result = Map.new(bars, fn {symbol, bar} -> {symbol, Bar.from_map(bar, symbol)} end)
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
    |> Keyword.take([:timeframe, :start, :end, :limit, :adjustment, :feed, :page_token])
    |> Enum.map(fn
      {:start, %DateTime{} = dt} -> {:start, DateTime.to_iso8601(dt)}
      {:end, %DateTime{} = dt} -> {:end, DateTime.to_iso8601(dt)}
      other -> other
    end)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_bars(%{"bars" => bars}, symbol) when is_list(bars) do
    Enum.map(bars, &Bar.from_map(&1, symbol))
  end

  defp parse_bars(%{"bars" => nil}, _symbol), do: []
  defp parse_bars(_, _symbol), do: []

  defp parse_multi_bars(%{"bars" => bars}) when is_map(bars) do
    Map.new(bars, fn {symbol, bar_list} ->
      {symbol, Enum.map(bar_list, &Bar.from_map(&1, symbol))}
    end)
  end

  defp parse_multi_bars(%{"bars" => nil}), do: %{}
  defp parse_multi_bars(_), do: %{}
end
