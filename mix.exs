defmodule Alpa.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/phiat/alpa_ex"

  def project do
    [
      app: :alpa_ex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "AlpaEx",
      source_url: @source_url,
      homepage_url: @source_url,
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {Alpa.Application, []}
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp description do
    """
    Elixir client library for the Alpaca Trading API.
    Supports trading, market data, and account management.
    """
  end

  defp package do
    [
      maintainers: ["phiat"],
      licenses: ["MIT"],
      files: ~w(lib config assets mix.exs README.md CHANGELOG.md LICENSE),
      links: %{
        "GitHub" => @source_url,
        "Alpaca API Docs" => "https://docs.alpaca.markets"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/Getting-Started.md",
        "docs/Architecture.md",
        "docs/API-Coverage.md",
        "docs/Trading-Strategies.md",
        "docs/Contributing.md"
      ],
      source_ref: "v#{@version}",
      groups_for_modules: [
        Trading: [
          Alpa.Trading.Account,
          Alpa.Trading.Orders,
          Alpa.Trading.Positions,
          Alpa.Trading.Assets,
          Alpa.Trading.Watchlists,
          Alpa.Trading.Market,
          Alpa.Trading.CorporateActions
        ],
        "Market Data": [
          Alpa.MarketData.Bars,
          Alpa.MarketData.Quotes,
          Alpa.MarketData.Trades,
          Alpa.MarketData.Snapshots
        ],
        Streaming: [
          Alpa.Stream.TradeUpdates,
          Alpa.Stream.MarketData
        ],
        Options: [
          Alpa.Options.Contracts
        ],
        Crypto: [
          Alpa.Crypto.Trading,
          Alpa.Crypto.MarketData,
          Alpa.Crypto.Funding
        ],
        Core: [
          Alpa.Client,
          Alpa.Config,
          Alpa.Error,
          Alpa.Pagination
        ],
        Models: ~r/Alpa\.Models\./
      ]
    ]
  end

  defp deps do
    [
      # HTTP client
      {:req, "~> 0.5"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # Typed structs
      {:typed_struct, "~> 0.3"},

      # Decimal for financial precision
      {:decimal, "~> 2.0"},

      # WebSocket client for streaming
      {:websockex, "~> 0.4"},

      # Telemetry for API call instrumentation
      {:telemetry, "~> 1.0"},

      # Development & Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.15", only: :test},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
