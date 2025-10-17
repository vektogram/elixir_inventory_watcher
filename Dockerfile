# Backend/Dockerfile
FROM elixir:1.15-alpine AS builder

# Install build deps
RUN apk add --no-cache build-base git nodejs npm postgresql-dev

WORKDIR /app
COPY . .

# Get deps and compile
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix deps.compile

# Build assets
RUN MIX_ENV=prod mix assets.deploy

# Compile app
RUN MIX_ENV=prod mix compile

# Create release
RUN MIX_ENV=prod mix release

# Production stage
FROM alpine:3.18
RUN apk add --no-cache libstdc++ openssl ncurses-libs bash postgresql-client

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/inventory_watcher ./

# Run migrations on start using the release binary
RUN printf '#!/bin/sh\n/app/bin/inventory_watcher eval "InventoryWatcher.Release.migrate()"\nexec "$@"\n' > entrypoint.sh && chmod +x entrypoint.sh

EXPOSE 4000
ENTRYPOINT ["./entrypoint.sh"]
CMD ["bin/inventory_watcher", "start"]