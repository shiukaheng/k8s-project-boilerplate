# Hasura GraphQL Engine

This directory contains Hasura configuration, migrations, and metadata for the DAG Todo application.

## Structure

```
hasura/
├── config.yaml              # CLI configuration
├── migrations/              # Database schema migrations
│   └── default/
│       └── <timestamp>_<name>/
│           ├── up.sql
│           └── down.sql
└── metadata/                # Hasura metadata (tables, permissions, relationships)
    └── databases/
        └── databases.yaml
```

## Workflow

### Development

1. Start dev environment:
   ```bash
   tilt up
   ```

2. Open Hasura Console:
   ```bash
   # Via port-forward (automatic)
   open http://localhost:8080/console
   
   # Or via hasura CLI
   cd hasura
   hasura console
   ```

3. Make changes in the UI (create tables, relationships, permissions)

4. Export changes:
   ```bash
   hasura migrate create <name> --from-server
   hasura metadata export
   ```

### Applying Migrations

```bash
# Apply all pending migrations
hasura migrate apply

# Apply specific migration
hasura migrate apply --version <timestamp>

# Rollback last migration
hasura migrate apply --down 1
```

## Environment Variables

| Variable | Dev Value | Description |
|----------|-----------|-------------|
| HASURA_GRAPHQL_ADMIN_SECRET | `hasura` | Admin secret for console access |
| HASURA_GRAPHQL_ENABLE_CONSOLE | `true` | Enable web console |
| HASURA_GRAPHQL_DATABASE_URL | `postgres://...` | PostgreSQL connection |

## Connecting to Database

Hasura connects to the existing PostgreSQL instance deployed by Helm:
- Host: `postgres` (service name in Kubernetes)
- Database: `postgres`
- User: `postgres`
- Password: `password`

Both Hasura metadata and application data are stored in the same database (separate schemas: `hdb_catalog` and `public`).
