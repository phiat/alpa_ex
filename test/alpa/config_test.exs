defmodule Alpa.ConfigTest do
  # Not async because environment variable tests modify global state
  use ExUnit.Case, async: false

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

  describe "environment variables" do
    setup do
      # Store original env values
      original_key = System.get_env("APCA_API_KEY_ID")
      original_secret = System.get_env("APCA_API_SECRET_KEY")
      original_paper = System.get_env("APCA_USE_PAPER")

      # Clear env vars before each test
      System.delete_env("APCA_API_KEY_ID")
      System.delete_env("APCA_API_SECRET_KEY")
      System.delete_env("APCA_USE_PAPER")

      on_exit(fn ->
        # Restore original values
        if original_key, do: System.put_env("APCA_API_KEY_ID", original_key), else: System.delete_env("APCA_API_KEY_ID")
        if original_secret, do: System.put_env("APCA_API_SECRET_KEY", original_secret), else: System.delete_env("APCA_API_SECRET_KEY")
        if original_paper, do: System.put_env("APCA_USE_PAPER", original_paper), else: System.delete_env("APCA_USE_PAPER")
      end)

      :ok
    end

    test "reads api_key from APCA_API_KEY_ID" do
      System.put_env("APCA_API_KEY_ID", "env-key-123")
      config = Config.new([])
      assert config.api_key == "env-key-123"
    end

    test "reads api_secret from APCA_API_SECRET_KEY" do
      System.put_env("APCA_API_SECRET_KEY", "env-secret-456")
      config = Config.new([])
      assert config.api_secret == "env-secret-456"
    end

    test "reads use_paper from APCA_USE_PAPER" do
      System.put_env("APCA_USE_PAPER", "false")
      config = Config.new([])
      assert config.use_paper == false
    end

    test "options override environment variables" do
      System.put_env("APCA_API_KEY_ID", "env-key")
      config = Config.new(api_key: "option-key")
      assert config.api_key == "option-key"
    end
  end
end
