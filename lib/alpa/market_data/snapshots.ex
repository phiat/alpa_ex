defmodule Alpa.MarketData.Snapshots do
  @moduledoc """
  Market snapshots from the Alpaca Market Data API v2.

  A snapshot provides a comprehensive view of a stock including:
  - Latest trade
  - Latest quote (NBBO)
  - Minute bar
  - Daily bar
  - Previous daily bar
  """

  alias Alpa.Client
  alias Alpa.Models.Snapshot

  @doc """
  Get a snapshot for a single symbol.

  ## Options

    * `:feed` - Data feed: "iex", "sip"

  ## Examples

      iex> Alpa.MarketData.Snapshots.get("AAPL")
      {:ok, %Alpa.Models.Snapshot{
        symbol: "AAPL",
        latest_trade: %Alpa.Models.Trade{...},
        latest_quote: %Alpa.Models.Quote{...},
        minute_bar: %Alpa.Models.Bar{...},
        daily_bar: %Alpa.Models.Bar{...},
        prev_daily_bar: %Alpa.Models.Bar{...}
      }}

  """
  @spec get(String.t(), keyword()) :: {:ok, Snapshot.t()} | {:error, Alpa.Error.t()}
  def get(symbol, opts \\ []) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    encoded_symbol = URI.encode_www_form(symbol)

    case Client.get_data("/v2/stocks/#{encoded_symbol}/snapshot", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, Snapshot.from_map(data, symbol)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get snapshots for multiple symbols.

  ## Options

    * `:feed` - Data feed: "iex", "sip"

  ## Examples

      iex> Alpa.MarketData.Snapshots.get_multi(["AAPL", "MSFT", "GOOGL"])
      {:ok, %{
        "AAPL" => %Alpa.Models.Snapshot{...},
        "MSFT" => %Alpa.Models.Snapshot{...},
        "GOOGL" => %Alpa.Models.Snapshot{...}
      }}

  """
  @spec get_multi([String.t()], keyword()) ::
          {:ok, %{String.t() => Snapshot.t()}} | {:error, Alpa.Error.t()}
  def get_multi(symbols, opts \\ []) when is_list(symbols) do
    params =
      opts
      |> Keyword.take([:feed])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.put(:symbols, Enum.join(symbols, ","))

    case Client.get_data("/v2/stocks/snapshots", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, Snapshot.from_response(data)}
      {:error, _} = error -> error
    end
  end
end
