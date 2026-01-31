defmodule Alpa.Models.PortfolioHistory do
  @moduledoc """
  Portfolio history model for historical account values.
  """
  use TypedStruct

  typedstruct do
    field(:timestamp, [integer()])
    field(:equity, [number() | nil])
    field(:profit_loss, [number() | nil])
    field(:profit_loss_pct, [number() | nil])
    field(:base_value, number())
    field(:base_value_asof, String.t())
    field(:timeframe, String.t())
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      timestamp: data["timestamp"],
      equity: data["equity"],
      profit_loss: data["profit_loss"],
      profit_loss_pct: data["profit_loss_pct"],
      base_value: data["base_value"],
      base_value_asof: data["base_value_asof"],
      timeframe: data["timeframe"]
    }
  end
end
