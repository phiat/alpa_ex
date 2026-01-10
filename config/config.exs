import Config

# Default configuration for Alpa
# Override these in your application's config or via environment variables

config :alpa,
  # API endpoints
  trading_url: "https://api.alpaca.markets",
  paper_url: "https://paper-api.alpaca.markets",
  data_url: "https://data.alpaca.markets",

  # Default to paper trading for safety
  use_paper: true,

  # Request settings
  timeout: 30_000,
  receive_timeout: 30_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
