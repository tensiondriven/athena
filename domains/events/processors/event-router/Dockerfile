FROM hexpm/elixir:1.14.5-erlang-25.3.2.8-alpine-3.18.4

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache build-base git curl

# Install hex and rebar
RUN mix local.hex --force &&     mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Set environment
ENV MIX_ENV=prod

# Install dependencies
RUN mix deps.get --only=prod
RUN mix deps.compile

# Copy source code
COPY . .

# Compile the project
RUN mix compile

# Create release
RUN mix release

# Install curl for healthcheck
RUN apk add --no-cache curl

EXPOSE 4000

CMD ["_build/prod/rel/claude_collector/bin/claude_collector", "start"]
EOF'
