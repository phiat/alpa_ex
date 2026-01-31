defmodule Alpa.Models.Calendar do
  @moduledoc """
  Market calendar entry.
  """
  use TypedStruct

  typedstruct do
    field(:date, Date.t())
    field(:open, String.t())
    field(:close, String.t())
    field(:session_open, String.t())
    field(:session_close, String.t())
    field(:settlement_date, Date.t())
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      date: parse_date(data["date"]),
      open: data["open"],
      close: data["close"],
      session_open: data["session_open"],
      session_close: data["session_close"],
      settlement_date: parse_date(data["settlement_date"])
    }
  end

  defp parse_date(nil), do: nil

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
