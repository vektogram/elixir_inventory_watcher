# Inventory Watcher — Technical Reference

This document provides an implementation-level walkthrough of the `inventory_watcher` backend. It complements, but does not replace, the project README.

## 1. Runtime Topology

- **Language / VM**: Elixir 1.15 on the Erlang/OTP BEAM VM.
- **HTTP Server**: Bandit (Phoenix 1.7 default) bound to IPv6 `::`.
- **Web Framework**: Phoenix with Absinthe for GraphQL.
- **Database**: PostgreSQL accessed via Ecto (`InventoryWatcher.Repo`).
- **PubSub**: Phoenix.PubSub (in-memory); suitable for single node, configurable for Redis/PG2 scaling.
- **Release**: OTP release built by `MIX_ENV=prod mix release`, wrapped in a multi-stage Docker image.

### Supervisor Tree (`InventoryWatcher.Application`)

1. `InventoryWatcherWeb.Telemetry`
2. `InventoryWatcher.Repo`
3. `DNSCluster`
4. `{Phoenix.PubSub, name: InventoryWatcher.PubSub}`
5. `{Finch, name: InventoryWatcher.Finch}`
6. `InventoryWatcherWeb.Endpoint`
7. `{Absinthe.Subscription, InventoryWatcherWeb.Endpoint}`

The Absinthe subscription supervisor persists subscription data and bridges Phoenix PubSub with Absinthe execution.

## 2. Domain + Persistence Layer

### Schema (`lib/inventory_watcher/product.ex`)

```elixir
schema "products" do
  field :name, :string
  field :sku, :string
  field :stock_count, :integer
  timestamps()
end
```

- `unique_constraint(:sku)` prevents duplicate catalog entries.
- `validate_number(:stock_count, greater_than_or_equal_to: 0)` guarantees non-negative inventory counts.

### Migration (`priv/repo/migrations/20251017190105_create_products.exs`)

Creates `products` with default `stock_count` of 0 and adds a unique BTree index on `sku`.

### Repo (`lib/inventory_watcher/repo.ex`)

Standard Ecto Repo configured via `config/runtime.exs`. Connection pooling is controlled by the `POOL_SIZE` environment variable (default 10).

## 3. GraphQL Schema

Defined in `lib/inventory_watcher_web/schema.ex` with type definitions under `lib/inventory_watcher_web/schema/product_types.ex`.

### Operations

- **Query.products** — returns `Repo.all(Product)` via `InventoryWatcherWeb.Resolvers.ProductResolver`.
- **Subscription.stock_updated** — streams product structs on topic `"products:stock_updates"`.

### WebSocket Integration

- `InventoryWatcherWeb.UserSocket` extends `Absinthe.Phoenix.Socket` and injects `%{pubsub: InventoryWatcherWeb.Endpoint}` into the Absinthe context during `connect/3`.
- `InventoryWatcher.ProductService` publishes with `Absinthe.Subscription.publish/3` after successful stock updates.

## 4. HTTP Surface

`lib/inventory_watcher_web/router.ex` defines three relevant scopes:

| Method | Path                         | Pipeline   | Handler                                | Purpose               |
| ------ | ---------------------------- | ---------- | -------------------------------------- | --------------------- |
| GET    | `/`                          | `:browser` | `PageController.home`                  | Demo landing page     |
| POST   | `/api/graphql`               | `:graphql` | `Absinthe.Plug`                        | GraphQL endpoint      |
| WS     | `/socket/websocket`          | —          | `InventoryWatcherWeb.UserSocket`       | GraphQL subscriptions |
| POST   | `/api/simulate-stock-update` | `:api`     | `PageController.simulate_stock_update` | Demo stock mutator    |
| GET    | `/api/graphiql` (dev)        | `:graphql` | `Absinthe.Plug.GraphiQL`               | Embedded IDE          |

`PageController.simulate_stock_update/2` delegates to `InventoryWatcher.ProductService.simulate_stock_update/0`, which randomly offsets stock between -5 and +10, clamped to ≥ 0.

## 5. Event Flow

```
HTTP POST /api/simulate-stock-update
   ↳ ProductService.simulate_stock_update/0
       ↳ ProductService.update_stock/2
           ↳ Repo.update/1 (products table)
           ↳ Absinthe.Subscription.publish/3 (topic "products:stock_updates")
               ↳ Absinthe subscription supervisor
                   ↳ Re-resolves stockUpdated field
                       ↳ Broadcast via WebSocket to connected clients
```

The React/Vite frontend consumes this via Apollo Client over `wss://<backend>/socket`.

## 6. Runtime Configuration (`config/runtime.exs`)

All sensitive settings are sourced from environment variables:

| Env Var                             | Description                                |
| ----------------------------------- | ------------------------------------------ |
| `DATABASE_URL`                      | PostgreSQL connection URI                  |
| `POOL_SIZE`                         | Ecto connection pool size                  |
| `SECRET_KEY_BASE`                   | Phoenix secret (cookie signing, etc.)      |
| `PHX_HOST`                          | Public host advertised in generated URLs   |
| `PORT`                              | HTTP listen port (default 4000)            |
| `FRONTEND_URL` / `FRONTEND_ORIGINS` | Comma-separated list of allowed origins    |
| `CHECK_ORIGIN`                      | Optional override for strict origin checks |
| `PHX_SERVER`                        | Enables server start inside releases       |

`force_ssl: [rewrite_on: [:x_forwarded_proto]]` ensures Phoenix respects Traefik’s TLS termination.

`config :cors_plug` is populated at runtime to allow the deployed frontend (e.g., `https://softworldinc.cesarcm.com`) to call GraphQL and upgrade to WebSockets.

## 7. Docker Image Lifecycle

- **Builder stage** (`elixir:1.15-alpine`): installs build deps, fetches prod packages, compiles assets (`MIX_ENV=prod mix assets.deploy`), builds release (`mix release`).
- **Runtime stage** (`alpine:3.18`): copies release artifacts, writes entrypoint script that runs `InventoryWatcher.Release.migrate/0` before delegating to `bin/inventory_watcher start`.

`entrypoint.sh`:

```sh
#!/bin/sh
/app/bin/inventory_watcher eval "InventoryWatcher.Release.migrate()"
exec "$@"
```

This guarantees migrations run on every deploy. Seeds are triggered manually via `/app/bin/inventory_watcher eval "InventoryWatcher.Release.seed()"` when necessary.

## 8. Deployment on Dokploy

1. Push to GitHub (`main` branch).
2. Dokploy builds the Dockerfile and redeploys the OTP release.
3. Traefik proxies `https://elixirapi01.cesarcm.com` → container port `4000`.
4. Required env vars: `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST`, `FRONTEND_URL`, `PHX_SERVER=true`, `PORT=4000`, `POOL_SIZE`.
5. Optional worker container runs the high-frequency stock simulation loop for demos.

## 9. Observability & Tooling

- **Telemetry Metrics**: `InventoryWatcherWeb.Telemetry` enables Phoenix LiveDashboard for request/VM insights (only in dev unless secured).
- **Logging**: Phoenix logs origin rejections, pubsub events, and errors; inspect Dokploy service logs when debugging CORS or subscription issues.
- **Test Scripts**:
  - `test_subscription.exs`: WebSockex client to validate the subscription handshake.
  - `test_broadcast.exs`: Direct Absinthe subscription harness.

## 10. Security Considerations

- `/api/simulate-stock-update` is public for demo purposes; protect it (API key, basic auth, IP allow-list) or disable in production.
- Ensure `SECRET_KEY_BASE` is unique per environment and never committed.
- Consider switching Phoenix.PubSub to Redis when clustering across nodes.
- Implement rate limiting on GraphQL mutations/queries if exposing publicly.

## 11. Troubleshooting Matrix

| Issue                     | Diagnosis                                                            | Mitigation                                                                                              |
| ------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `Origin ... not allowed`  | Env vars missing scheme (`https://`) or not redeployed               | Update Dokploy env to full URL, redeploy                                                                |
| `Pubsub not configured!`  | Subscription supervisor not running or socket context missing pubsub | Ensure `{Absinthe.Subscription, Endpoint}` is supervised and `UserSocket` inserts `%{pubsub: Endpoint}` |
| WebSocket handshake fails | Traefik not forwarding Upgrade headers or `PHX_HOST` mismatch        | Check Traefik config, confirm TLS certs, align `PHX_HOST`                                               |
| Migrations skipped        | Invalid DB credentials or entrypoint failure                         | Inspect Dokploy logs, validate `DATABASE_URL`                                                           |
| Stock updates missing     | Validation failure on `Product.changeset/2`                          | Review logs for changeset errors                                                                        |

## 12. Future Enhancements

- Add authenticated mutations for manual stock adjustments.
- Replace demo HTTP endpoint with a background worker + queue.
- Externalize Absinthe subscription storage (Redis/Postgres) for multi-node deployment.
- Instrument GraphQL resolvers with Absinthe telemetry for fine-grained monitoring.
- Extend schema with warehouses, allocations, and reorder alerts.

---

For quick-start instructions, refer to the original `README.md`. This document is intended for engineers maintaining or extending the backend runtime.
