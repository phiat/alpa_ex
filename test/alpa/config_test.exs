defmodule Alpa.ConfigTest do
  use ExUnit.Case, async: true

  alias Alpa.Config

  describe "new/1" do
    test "creates config with defaults" do
      config = Config.new([])

      assert config.use_paper == true
      assert config.timeout == 30_000
      assert config.receive_timeout == 30_000
    end

    test "accepts api credentials as options" do
      config = Config.new(api_key: "test-key", api_secret: "test-secret")

      assert config.api_key == "test-key"
      assert config.api_secret == "test-secret"
    end

    test "respects use_paper option" do
      config = Config.new(use_paper: false)
      assert config.use_paper == false
    end

    test "accepts custom timeouts" do
      config = Config.new(timeout: 60_000, receive_timeout: 90_000)

      assert config.timeout == 60_000
      assert config.receive_timeout == 90_000
    end
  end

  describe "trading_url/1" do
    test "returns paper URL when use_paper is true" do
      config = Config.new(use_paper: true)
      assert Config.trading_url(config) == "https://paper-api.alpaca.markets"
    end

    test "returns live URL when use_paper is false" do
      config = Config.new(use_paper: false)
      assert Config.trading_url(config) == "https://api.alpaca.markets"
    end
  end

  describe "data_url/1" do
    test "returns default data URL" do
      config = Config.new([])
      assert Config.data_url(config) == "https://data.alpaca.markets"
    end
  end

  describe "has_credentials?/1" do
    test "returns true when both key and secret are present" do
      config = Config.new(api_key: "key", api_secret: "secret")
      assert Config.has_credentials?(config) == true
    end

    test "returns false when key is missing" do
      config = Config.new(api_secret: "secret")
      assert Config.has_credentials?(config) == false
    end

    test "returns false when secret is missing" do
      config = Config.new(api_key: "key")
      assert Config.has_credentials?(config) == false
    end

    test "returns false when both are missing" do
      config = Config.new([])
      assert Config.has_credentials?(config) == false
    end

    test "returns false for empty strings" do
      config = Config.new(api_key: "", api_secret: "")
      assert Config.has_credentials?(config) == false
    end
  end
end
