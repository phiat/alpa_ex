defmodule Alpa.Models.Clock do
  @moduledoc """
  Market clock information.
  """
  use TypedStruct

  typedstruct do
    field :timestamp, DateTime.t()
    field :is_open, boolean()
    field :next_open, DateTime.t()
    field :next_close, DateTime.t()
  end

  @doc """
  Parse clock data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      timestamp: parse_datetime(data["timestamp"]),
      is_open: data["is_open"],
      next_open: parse_datetime(data["next_open"]),
      next_close: parse_datetime(data["next_close"])
    }
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
end
