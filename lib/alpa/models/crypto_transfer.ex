defmodule Alpa.Models.CryptoTransfer do
  @moduledoc """
  Crypto funding transfer model.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1, parse_datetime: 1]

  typedstruct do
    field :id, String.t()
    field :tx_hash, String.t()
    field :direction, String.t()
    field :status, String.t()
    field :amount, Decimal.t()
    field :symbol, String.t()
    field :network_fee, Decimal.t()
    field :fees, Decimal.t()
    field :chain, String.t()
    field :from_address, String.t()
    field :to_address, String.t()
    field :created_at, DateTime.t()
    field :updated_at, DateTime.t()
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      tx_hash: data["tx_hash"],
      direction: data["direction"],
      status: data["status"],
      amount: parse_decimal(data["amount"]),
      symbol: data["symbol"],
      network_fee: parse_decimal(data["network_fee"]),
      fees: parse_decimal(data["fees"]),
      chain: data["chain"],
      from_address: data["from_address"],
      to_address: data["to_address"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"])
    }
  end

end
