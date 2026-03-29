# Custom Hasura Chart Strategy

## Why the official chart doesn't support this

The official `hasura/graphql-engine` Helm chart uses the standard image, which has no mechanism for loading metadata from a file. Hasura stores its configuration (tracked tables, relationships, permissions, sources) exclusively in its metadata database (`hdb_catalog` schema). The only way to get metadata *into* a running Hasura is via its `replace_metadata` API.

The `cli-migrations-v3` image variant solves this, but requires a specific on-disk YAML directory format — not the single JSON blob that the Hasura console exports. It also doesn't fit the "just another values.yaml" model.

## What we do instead

We fork the official chart to `charts/hasura/` and add three things:

### 1. Bundled ephemeral metadata database

A dedicated `postgres:16-alpine` Deployment + Service is co-located inside the chart (`templates/metadata-postgres.yaml`). It uses `emptyDir` storage — no PVC, ever. This is intentional: Hasura's configuration state lives in the chart values, not in a database.

```
HASURA_GRAPHQL_METADATA_DATABASE_URL → hasura-metadata-postgres (always ephemeral, in-chart)
HASURA_GRAPHQL_DATABASE_URL          → postgres-postgresql (app data, ephemeral in dev, persistent in prod)
```

The `db.url` helper in `_helpers.tpl` auto-constructs the metadata URL when `metadataPostgres.enabled: true`, so no manual URL is needed in `common.yaml`.

### 2. Declarative metadata value

`metadataJson` is a new chart value that accepts the JSON blob from Hasura's "Export metadata" button (or `export_metadata` API). It is stored in a ConfigMap rendered from the chart template.

```yaml
# deploy/values/hasura/common.yaml
metadataJson: |
  {
    "resource_version": 7,
    "metadata": { ... }
  }
```

**Format note:** Paste the full console export as-is. The startup script handles both formats:
- Console export: `{"resource_version": N, "metadata": {...}}` — inner `metadata` field is extracted
- Raw metadata: `{"version": 3, "sources": [...]}` — used directly

A `checksum/metadata` annotation on the Deployment pod template means the pod automatically rolls whenever `metadataJson` changes.

### 3. Entrypoint wrapper

When `metadataJson` is set, the chart overrides the container command with a bash script:

```
graphql-engine serve &          # start in background
poll /dev/tcp until port 8080   # wait for ready (no curl needed — pure bash)
POST /v1/metadata replace_metadata with JSON from mounted ConfigMap
wait $GE_PID                    # foreground the server process
```

This runs on **every container start** — fresh deploys, pod restarts, crashes. No Helm hooks, no Jobs, no sidecars.

## Startup sequence

```
hasura-metadata-postgres starts  →  empty DB
graphql-engine starts            →  connects, creates hdb_catalog schema
bash wrapper fires               →  replace_metadata applied from ConfigMap
Hasura serves                    →  fully configured, consistent state
```

## Workflow

**To update Hasura configuration:**

1. Make changes in the Hasura console
2. Click "Export metadata" (or run `hasura metadata export --output json`)
3. Paste the JSON into `metadataJson` in `deploy/values/hasura/common.yaml`
4. Tilt detects the change → pod rolls → metadata re-applied on startup

**To reset completely:**

`tilt down && tilt up` — both postgres instances start fresh, metadata is re-applied from the chart.

## Upstream chart updates

`charts/hasura/` is a fork of `hasura/graphql-engine` chart at version `0.9.1`. Changes are confined to:
- `Chart.yaml` — removed bundled postgres dependency
- `values.yaml` — added `metadataPostgres`, `metadataJson` defaults
- `templates/metadata-postgres.yaml` — new file
- `templates/metadata-configmap.yaml` — new file
- `templates/deployment.yaml` — checksum annotation, command override, volume/mount (all gated on `metadataJson`)
- `templates/_helpers.tpl` — extended `db.url` helper
- `templates/secrets.yaml` — condition for `METADATA_DATABASE_URL`

When merging upstream chart updates, only these files need reviewing.
