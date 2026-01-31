defmodule Alpa.Models.CorporateAction do
  @moduledoc """
  Corporate action announcement model.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1, parse_date: 1]

  typedstruct do
    field :id, String.t()
    field :corporate_action_id, String.t()
    field :ca_type, String.t()
    field :ca_sub_type, String.t()
    field :initiating_symbol, String.t()
    field :initiating_original_cusip, String.t()
    field :target_symbol, String.t()
    field :target_original_cusip, String.t()
    field :declaration_date, Date.t()
    field :ex_date, Date.t()
    field :record_date, Date.t()
    field :payable_date, Date.t()
    field :cash, Decimal.t()
    field :old_rate, Decimal.t()
    field :new_rate, Decimal.t()
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      corporate_action_id: data["corporate_action_id"],
      ca_type: data["ca_type"],
      ca_sub_type: data["ca_sub_type"],
      initiating_symbol: data["initiating_symbol"],
      initiating_original_cusip: data["initiating_original_cusip"],
      target_symbol: data["target_symbol"],
      target_original_cusip: data["target_original_cusip"],
      declaration_date: parse_date(data["declaration_date"]),
      ex_date: parse_date(data["ex_date"]),
      record_date: parse_date(data["record_date"]),
      payable_date: parse_date(data["payable_date"]),
      cash: parse_decimal(data["cash"]),
      old_rate: parse_decimal(data["old_rate"]),
      new_rate: parse_decimal(data["new_rate"])
    }
  end

end
