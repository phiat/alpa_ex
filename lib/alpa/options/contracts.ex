defmodule Alpa.Options.Contracts do
  @moduledoc """
  Options contract operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.OptionContract

  @doc """
  Get option contracts with filtering.

  ## Options

    * `:underlying_symbols` - List of underlying symbols to filter by
    * `:status` - Contract status: "active", "inactive"
    * `:expiration_date` - Exact expiration date (Date or "YYYY-MM-DD")
    * `:expiration_date_gte` - Expiration date >= (Date or "YYYY-MM-DD")
    * `:expiration_date_lte` - Expiration date <= (Date or "YYYY-MM-DD")
    * `:root_symbol` - Option root symbol
    * `:type` - Option type: "call", "put"
    * `:style` - Option style: "american", "european"
    * `:strike_price_gte` - Strike price >=
    * `:strike_price_lte` - Strike price <=
    * `:limit` - Max contracts to return (default 100, max 10000)
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.Options.Contracts.list(underlying_symbols: ["AAPL"], type: "call")
      {:ok, %{contracts: [%Alpa.Models.OptionContract{...}], next_page_token: nil}}

  """
  @spec list(keyword()) ::
          {:ok, %{contracts: [OptionContract.t()], next_page_token: String.t() | nil}}
          | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    params =
      opts
      |> Keyword.take([
        :underlying_symbols,
        :status,
        :expiration_date,
        :expiration_date_gte,
        :expiration_date_lte,
        :root_symbol,
        :type,
        :style,
        :strike_price_gte,
        :strike_price_lte,
        :limit,
        :page_token
      ])
      |> Enum.map(fn
        {:underlying_symbols, syms} when is_list(syms) -> {:underlying_symbols, Enum.join(syms, ",")}
        {:expiration_date, %Date{} = d} -> {:expiration_date, Date.to_string(d)}
        {:expiration_date_gte, %Date{} = d} -> {:expiration_date_gte, Date.to_string(d)}
        {:expiration_date_lte, %Date{} = d} -> {:expiration_date_lte, Date.to_string(d)}
        other -> other
      end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/options/contracts", Keyword.put(opts, :params, params)) do
      {:ok, %{"option_contracts" => contracts, "next_page_token" => token}} ->
        parsed = Enum.map(contracts || [], &OptionContract.from_map/1)
        {:ok, %{contracts: parsed, next_page_token: token}}

      {:ok, %{"option_contracts" => contracts}} ->
        parsed = Enum.map(contracts || [], &OptionContract.from_map/1)
        {:ok, %{contracts: parsed, next_page_token: nil}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get a specific option contract by symbol or ID.

  ## Examples

      iex> Alpa.Options.Contracts.get("AAPL230120C00150000")
      {:ok, %Alpa.Models.OptionContract{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, OptionContract.t()} | {:error, Alpa.Error.t()}
  def get(symbol_or_id, opts \\ []) do
    case Client.get("/v2/options/contracts/#{URI.encode_www_form(symbol_or_id)}", opts) do
      {:ok, data} -> {:ok, OptionContract.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Search for option contracts by underlying symbol with common filters.

  This is a convenience function that wraps `list/1`.

  ## Examples

      iex> Alpa.Options.Contracts.search("AAPL", type: :call, expiration_date_gte: ~D[2024-03-01])
      {:ok, %{contracts: [...], next_page_token: nil}}

  """
  @spec search(String.t(), keyword()) ::
          {:ok, %{contracts: [OptionContract.t()], next_page_token: String.t() | nil}}
          | {:error, Alpa.Error.t()}
  def search(underlying_symbol, opts \\ []) do
    opts = Keyword.put(opts, :underlying_symbols, [underlying_symbol])

    # Convert atom type to string
    opts =
      case Keyword.get(opts, :type) do
        :call -> Keyword.put(opts, :type, "call")
        :put -> Keyword.put(opts, :type, "put")
        _ -> opts
      end

    list(opts)
  end
end
