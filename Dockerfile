# Use official Elixir image
FROM elixir:1.16-otp-26-slim

# Install build deps
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy dependency files first (cache layer)
COPY mix.exs mix.lock ./
RUN mix deps.get && mix deps.compile

# Copy source
COPY . .

# Compile
RUN mix compile --warnings-as-errors

# Default command
CMD ["mix", "test"]
