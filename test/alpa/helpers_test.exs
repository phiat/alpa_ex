defmodule Alpa.HelpersTest do
  use ExUnit.Case, async: true

  alias Alpa.Helpers

  describe "parse_decimal/1" do
    test "parses a valid decimal string" do
      result = Helpers.parse_decimal("123.45")
      assert Decimal.eq?(result, Decimal.new("123.45"))
    end

    test "parses an integer string" do
      result = Helpers.parse_decimal("42")
      assert Decimal.eq?(result, Decimal.new("42"))
    end

    test "parses a negative decimal string" do
      result = Helpers.parse_decimal("-99.99")
      assert Decimal.eq?(result, Decimal.new("-99.99"))
    end

    test "parses zero" do
      result = Helpers.parse_decimal("0")
      assert Decimal.eq?(result, Decimal.new("0"))
    end

    test "parses a string with trailing non-numeric characters" do
      result = Helpers.parse_decimal("123.45abc")
      assert Decimal.eq?(result, Decimal.new("123.45"))
    end

    test "returns nil for nil" do
      assert Helpers.parse_decimal(nil) == nil
    end

    test "returns nil for unparseable string" do
      assert Helpers.parse_decimal("not-a-number") == nil
    end

    test "returns nil for empty string" do
      assert Helpers.parse_decimal("") == nil
    end

    test "handles integer input" do
      result = Helpers.parse_decimal(42)
      assert Decimal.eq?(result, Decimal.new(42))
    end

    test "handles float input" do
      result = Helpers.parse_decimal(3.14)
      assert Decimal.eq?(result, Decimal.from_float(3.14))
    end

    test "handles very large decimal string" do
      result = Helpers.parse_decimal("999999999999999.99")
      assert Decimal.eq?(result, Decimal.new("999999999999999.99"))
    end

    test "handles very small decimal string" do
      result = Helpers.parse_decimal("0.00000001")
      assert Decimal.eq?(result, Decimal.new("0.00000001"))
    end
  end

  describe "parse_datetime/1" do
    test "parses ISO 8601 UTC datetime" do
      result = Helpers.parse_datetime("2024-01-15T14:30:00Z")
      assert result == ~U[2024-01-15 14:30:00Z]
    end

    test "parses datetime with offset" do
      result = Helpers.parse_datetime("2024-01-15T14:30:00-05:00")
      assert %DateTime{} = result
    end

    test "parses datetime with microseconds" do
      result = Helpers.parse_datetime("2024-01-15T14:30:00.123456Z")
      assert %DateTime{} = result
      assert result.microsecond == {123_456, 6}
    end

    test "returns nil for nil" do
      assert Helpers.parse_datetime(nil) == nil
    end

    test "returns nil for invalid datetime string" do
      assert Helpers.parse_datetime("not-a-date") == nil
    end

    test "returns nil for empty string" do
      assert Helpers.parse_datetime("") == nil
    end
  end

  describe "parse_date/1" do
    test "parses ISO 8601 date" do
      result = Helpers.parse_date("2024-01-15")
      assert result == ~D[2024-01-15]
    end

    test "returns nil for nil" do
      assert Helpers.parse_date(nil) == nil
    end

    test "returns nil for invalid date string" do
      assert Helpers.parse_date("not-a-date") == nil
    end

    test "returns nil for empty string" do
      assert Helpers.parse_date("") == nil
    end

    test "returns nil for invalid date values" do
      assert Helpers.parse_date("2024-13-45") == nil
    end
  end
end
