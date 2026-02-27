defmodule Alpa.Models.CryptoWallet do
  @moduledoc """
  Crypto wallet model for funding operations.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_datetime: 1]

  typedstruct do
    field(:id, String.t())
    field(:asset_id, String.t())
    field(:symbol, String.t())
    field(:status, String.t())
    field(:address, String.t())
    field(:created_at, DateTime.t())
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      asset_id: data["asset_id"],
      symbol: data["symbol"],
      status: data["status"],
      address: data["address"],
      created_at: parse_datetime(data["created_at"])
    }
  end
end
