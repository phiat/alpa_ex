defmodule Alpa.Crypto.Funding do
  @moduledoc """
  Crypto funding operations for the Alpaca Trading API.

  Manage crypto wallets and funding transfers.
  """

  alias Alpa.Client
  alias Alpa.Models.{CryptoWallet, CryptoTransfer}

  @doc """
  List crypto wallets.

  ## Examples

      iex> Alpa.Crypto.Funding.list_wallets()
      {:ok, [%Alpa.Models.CryptoWallet{...}]}

  """
  @spec list_wallets(keyword()) :: {:ok, [CryptoWallet.t()]} | {:error, Alpa.Error.t()}
  def list_wallets(opts \\ []) do
    case Client.get("/v2/crypto/funding/wallets", opts) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &CryptoWallet.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  List crypto funding transfers.

  ## Options

    * `:asset` - Filter by asset symbol (e.g., "BTC")

  ## Examples

      iex> Alpa.Crypto.Funding.list_transfers()
      {:ok, [%Alpa.Models.CryptoTransfer{...}]}

  """
  @spec list_transfers(keyword()) :: {:ok, [CryptoTransfer.t()]} | {:error, Alpa.Error.t()}
  def list_transfers(opts \\ []) do
    params =
      opts
      |> Keyword.take([:asset])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/crypto/funding/transfers", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &CryptoTransfer.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific crypto funding transfer.

  ## Examples

      iex> Alpa.Crypto.Funding.get_transfer("transfer-id")
      {:ok, %Alpa.Models.CryptoTransfer{...}}

  """
  @spec get_transfer(String.t(), keyword()) :: {:ok, CryptoTransfer.t()} | {:error, Alpa.Error.t()}
  def get_transfer(transfer_id, opts \\ []) do
    case Client.get("/v2/crypto/funding/transfers/#{transfer_id}", opts) do
      {:ok, data} -> {:ok, CryptoTransfer.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Request a crypto withdrawal.

  ## Parameters

    * `:amount` - Amount to withdraw (required)
    * `:address` - Destination wallet address (required)
    * `:symbol` - Crypto symbol, e.g. "BTC" (required)

  ## Examples

      iex> Alpa.Crypto.Funding.create_transfer(amount: "0.5", address: "bc1q...", symbol: "BTC")
      {:ok, %Alpa.Models.CryptoTransfer{...}}

  """
  @spec create_transfer(keyword()) :: {:ok, CryptoTransfer.t()} | {:error, Alpa.Error.t()}
  def create_transfer(params) when is_list(params) do
    body =
      params
      |> Keyword.take([:amount, :address, :symbol])
      |> Map.new()

    case Client.post("/v2/crypto/funding/transfers", body, params) do
      {:ok, data} -> {:ok, CryptoTransfer.from_map(data)}
      {:error, _} = error -> error
    end
  end
end
