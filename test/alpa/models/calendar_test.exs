defmodule Alpa.Models.CalendarTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Calendar

  describe "from_map/1" do
    test "parses complete calendar entry" do
      data = %{
        "date" => "2024-01-15",
        "open" => "09:30",
        "close" => "16:00",
        "session_open" => "04:00",
        "session_close" => "20:00",
        "settlement_date" => "2024-01-17"
      }

      cal = Calendar.from_map(data)

      assert cal.date == ~D[2024-01-15]
      assert cal.open == "09:30"
      assert cal.close == "16:00"
      assert cal.session_open == "04:00"
      assert cal.session_close == "20:00"
      assert cal.settlement_date == ~D[2024-01-17]
    end

    test "handles nil values" do
      cal = Calendar.from_map(%{})

      assert cal.date == nil
      assert cal.open == nil
      assert cal.close == nil
      assert cal.session_open == nil
      assert cal.session_close == nil
      assert cal.settlement_date == nil
    end

    test "handles invalid date format" do
      cal = Calendar.from_map(%{"date" => "not-a-date"})
      assert cal.date == nil
    end

    test "handles early close day" do
      data = %{
        "date" => "2024-11-29",
        "open" => "09:30",
        "close" => "13:00",
        "session_open" => "04:00",
        "session_close" => "13:00"
      }

      cal = Calendar.from_map(data)

      assert cal.date == ~D[2024-11-29]
      assert cal.close == "13:00"
    end

    test "parses settlement date separately from trade date" do
      data = %{
        "date" => "2024-01-15",
        "settlement_date" => "2024-01-17"
      }

      cal = Calendar.from_map(data)

      assert cal.date == ~D[2024-01-15]
      assert cal.settlement_date == ~D[2024-01-17]
      refute cal.date == cal.settlement_date
    end
  end
end
