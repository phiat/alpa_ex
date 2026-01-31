defmodule Alpa.Models.ClockTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Clock

  describe "from_map/1" do
    test "parses clock data when market is open" do
      data = %{
        "timestamp" => "2024-01-15T14:30:00-05:00",
        "is_open" => true,
        "next_open" => "2024-01-16T09:30:00-05:00",
        "next_close" => "2024-01-15T16:00:00-05:00"
      }

      clock = Clock.from_map(data)

      assert clock.timestamp != nil
      assert clock.is_open == true
      assert clock.next_open != nil
      assert clock.next_close != nil
    end

    test "parses clock data when market is closed" do
      data = %{
        "timestamp" => "2024-01-15T20:00:00-05:00",
        "is_open" => false,
        "next_open" => "2024-01-16T09:30:00-05:00",
        "next_close" => "2024-01-16T16:00:00-05:00"
      }

      clock = Clock.from_map(data)

      assert clock.is_open == false
      assert clock.next_open != nil
      assert clock.next_close != nil
    end

    test "handles nil values" do
      clock = Clock.from_map(%{})

      assert clock.timestamp == nil
      assert clock.is_open == nil
      assert clock.next_open == nil
      assert clock.next_close == nil
    end

    test "handles invalid timestamp" do
      clock = Clock.from_map(%{"timestamp" => "not-a-datetime"})
      assert clock.timestamp == nil
    end

    test "parses UTC timestamps" do
      data = %{
        "timestamp" => "2024-01-15T19:30:00Z",
        "is_open" => true,
        "next_open" => "2024-01-16T14:30:00Z",
        "next_close" => "2024-01-15T21:00:00Z"
      }

      clock = Clock.from_map(data)

      assert clock.timestamp.year == 2024
      assert clock.timestamp.month == 1
      assert clock.timestamp.day == 15
      assert clock.timestamp.hour == 19
    end
  end
end
