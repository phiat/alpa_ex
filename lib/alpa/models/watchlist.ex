defmodule Alpa.Models.Watchlist do
  @moduledoc """
  Watchlist model for organizing tracked assets.
  """
  use TypedStruct

  alias Alpa.Models.Asset

  typedstruct do
    field(:id, String.t())
    field(:account_id, String.t())
    field(:name, String.t())
    field(:created_at, DateTime.t())
    field(:updated_at, DateTime.t())
    field(:assets, [Asset.t()])
  end

  @doc """
  Parse watchlist data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      account_id: data["account_id"],
      name: data["name"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"]),
      assets: parse_assets(data["assets"])
    }
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_assets(nil), do: []
  defp parse_assets(assets) when is_list(assets), do: Enum.map(assets, &Asset.from_map/1)
end
