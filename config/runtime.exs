import Config

# Runtime configuration - loaded at runtime, not compile time
# This is the recommended place to configure API credentials

# Support both APCA_* (official) and ALPACA_* naming conventions
api_key = System.get_env("APCA_API_KEY_ID") || System.get_env("ALPACA_API_KEY")
api_secret = System.get_env("APCA_API_SECRET_KEY") || System.get_env("ALPACA_API_SECRET")

config :alpa,
  api_key: api_key,
  api_secret: api_secret,
  use_paper: System.get_env("APCA_USE_PAPER", "true") == "true"

# Optional: Override endpoints
if trading_url = System.get_env("APCA_API_TRADING_URL") do
  config :alpa, trading_url: trading_url
end

if paper_url = System.get_env("APCA_API_PAPER_URL") || System.get_env("ALPACA_API_ENDPOINT") do
  config :alpa, paper_url: paper_url
end

if data_url = System.get_env("APCA_API_DATA_URL") do
  config :alpa, data_url: data_url
end
