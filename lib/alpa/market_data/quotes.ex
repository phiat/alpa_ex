defmodule Alpa.MarketData.Quotes do
  @moduledoc """
  Quote (NBBO) data from the Alpaca Market Data API v2.
  """

  alias Alpa.Client
  alias Alpa.Models.Quote

  @doc """
  Get historical quotes for a single symbol.

  ## Required Parameters

    * `symbol` - Stock symbol (e.g., "AAPL")

  ## Options

    * `:start` - Start time (DateTime or ISO 8601 string)
    * `:end` - End time (DateTime or ISO 8601 string)
    * `:limit` - Max quotes to return (default 1000, max 10000)
    * `:feed` - Data feed: "iex", "sip"
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.MarketData.Quotes.get("AAPL", start: ~U[2024-01-15 14:30:00Z])
      {:ok, [%Alpa.Models.Quote{...}]}

  """
  @spec get(String.t(), keyword()) :: {:ok, [Quote.t()]} | {:error, Alpa.Error.t()}
  def get(symbol, opts \\ []) do
    params = build_params(opts)

    case Client.get_data("/v2/stocks/#{symbol}/quotes", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, parse_quotes(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get historical quotes for multiple symbols.

  ## Required Parameters

    * `symbols` - List of stock symbols (e.g., ["AAPL", "MSFT"])

  ## Options

  Same as `get/2`.

  ## Examples

      iex> Alpa.MarketData.Quotes.get_multi(["AAPL", "MSFT"], start: ~U[2024-01-15 14:30:00Z])
      {:ok, %{"AAPL" => [%Alpa.Models.Quote{...}], "MSFT" => [%Alpa.Models.Quote{...}]}}

  """
  @spec get_multi([String.t()], keyword()) ::
          {:ok, %{String.t() => [Quote.t()]}} | {:error, Alpa.Error.t()}
  def get_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> build_params()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/quotes", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, parse_multi_quotes(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the latest quote for a symbol.

  ## Options

    * `:feed` - Data feed: "iex", "sip"

  ## Examples

      iex> Alpa.MarketData.Quotes.latest("AAPL")
      {:ok, %Alpa.Models.Quote{...}}

  """
  @spec latest(String.t(), keyword()) :: {:ok, Quote.t()} | {:error, Alpa.Error.t()}
  def latest(symbol, opts \\ []) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get_data("/v2/stocks/#{symbol}/quotes/latest", Keyword.put(opts, :params, params)) do
      {:ok, %{"quote" => quote}} -> {:ok, Quote.from_map(quote, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get latest quotes for multiple symbols.

  ## Examples

      iex> Alpa.MarketData.Quotes.latest_multi(["AAPL", "MSFT"])
      {:ok, %{"AAPL" => %Alpa.Models.Quote{...}, "MSFT" => %Alpa.Models.Quote{...}}}

  """
  @spec latest_multi([String.t()], keyword()) ::
          {:ok, %{String.t() => Quote.t()}} | {:error, Alpa.Error.t()}
  def latest_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/quotes/latest", Keyword.put(opts, :params, params)) do
      {:ok, %{"quotes" => quotes}} ->
        result = Map.new(quotes, fn {symbol, quote} -> {symbol, Quote.from_map(quote, symbol)} end)
        {:ok, result}

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

  defp parse_quotes(%{"quotes" => quotes}, symbol) when is_list(quotes) do
    Enum.map(quotes, &Quote.from_map(&1, symbol))
  end

  defp parse_quotes(%{"quotes" => nil}, _symbol), do: []
  defp parse_quotes(_, _symbol), do: []

  defp parse_multi_quotes(%{"quotes" => quotes}) when is_map(quotes) do
    Map.new(quotes, fn {symbol, quote_list} ->
      {symbol, Enum.map(quote_list, &Quote.from_map(&1, symbol))}
    end)
  end

  defp parse_multi_quotes(%{"quotes" => nil}), do: %{}
  defp parse_multi_quotes(_), do: %{}
end
