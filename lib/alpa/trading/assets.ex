defmodule Alpa.Trading.Assets do
  @moduledoc """
  Asset operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Asset

  @doc """
  Get all assets.

  ## Options

    * `:status` - Filter by status ("active", "inactive")
    * `:asset_class` - Filter by asset class ("us_equity", "crypto")
    * `:exchange` - Filter by exchange (e.g., "NASDAQ", "NYSE")

  ## Examples

      iex> Alpa.Trading.Assets.list()
      {:ok, [%Alpa.Models.Asset{...}]}

      iex> Alpa.Trading.Assets.list(status: "active", asset_class: "us_equity")
      {:ok, [%Alpa.Models.Asset{...}]}

  """
  @spec list(keyword()) :: {:ok, [Asset.t()]} | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    params =
      opts
      |> Keyword.take([:status, :asset_class, :exchange])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/assets", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Asset.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific asset by symbol or asset ID.

  ## Examples

      iex> Alpa.Trading.Assets.get("AAPL")
      {:ok, %Alpa.Models.Asset{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, Asset.t()} | {:error, Alpa.Error.t()}
  def get(symbol_or_asset_id, opts \\ []) do
    case Client.get("/v2/assets/#{URI.encode_www_form(symbol_or_asset_id)}", opts) do
      {:ok, data} -> {:ok, Asset.from_map(data)}
      {:error, _} = error -> error
    end
  end
end
