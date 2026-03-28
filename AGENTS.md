# AGENTS.md

> Context file for AI agents. **Always keep this file up to date** when making changes to this project.

## Project Overview

A full-stack web application for a **DAG-based Todo List** - tasks are represented as nodes in a Directed Acyclic Graph, with support for:
- **Task nodes**: Regular todos with completion state
- **Logic nodes**: AND/OR/NOT/XOR gates for conditional task completion
- **Edges**: Parent-child dependencies between nodes

Packaged as Helm charts for Kubernetes deployment.

---

## Architecture

This project follows a **six-layer architecture** (see FILE_STRUCTURE.md):

| Layer | Directory | Tool | Purpose |
|-------|-----------|------|--------|
| 1 | `workspace/` | npm workspaces | Source code (frontend, backend, shared lib) |
| 2 | `workspace/apps/*/Dockerfile` | Docker | Container image definitions |
| 3 | `charts/` | Helm | Kubernetes packaging per service |
| 4 | `deploy/` | Helmfile | Environment orchestration (dev/prod) |
| 5 | `Tiltfile` | Tilt | Dev iteration loop |
| 6 | `.github/`, `scripts/` | CI/CD | Production delivery |

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Frontend** | React 18, TypeScript, Vite, Tailwind CSS, nginx |
| **Backend** | Express.js, TypeScript, Node 22 |
| **Database** | PostgreSQL (Bitnami Helm chart) |
| **Shared Lib** | TypeScript (npm workspace package) |
| **Container Runtime** | Docker (multi-stage builds) |
| **Orchestration** | Kubernetes |
| **Packaging** | Helm 3 |
| **Deployment** | Helmfile |
| **Dev Iteration** | Tilt |
| **API Layer** | Hasura (planned) |

---

## Current Status

### Implemented
- Helm charts for `frontend` and `backend` (deployment + service templates)
- Helmfile orchestration with dev/prod environments
- External charts: PostgreSQL (bitnami), pgweb (ectobit)
- Ingress configuration (combined frontend/backend routing)
- Dockerfiles (multi-stage prod, dev variants with hot reload)
- Database schema (`table_creation.sql`) for DAG structure
- Tilt dev iteration setup

### Skeletal (Minimal Implementation)
- **Backend API**: Only `/hello` endpoint, no DB connection
- **Frontend**: Displays greeting only, no todo UI
- **Shared lib**: Exports single constant

### Missing / TODO
- Backend CRUD endpoints for users, nodes, edges
- Database connection (no ORM/client configured)
- DAG logic: cycle detection, topological sort, completion propagation
- Frontend todo UI and DAG visualization
- Shared types/models for domain entities
- Authentication/authorization
- CI/CD pipelines (GitHub Actions)
- Build/push/deploy scripts
- **Hasura GraphQL engine integration**
- **Database migration strategy** (Hasura migrations)
- **Hasura metadata configuration** (tables, permissions, relationships)

---

## Key Files

```
/mnt/workspace/repos/todo2/
├── table_creation.sql          # Database schema (users, nodes, edges) - DEPRECATED
├── deploy/helmfile.yaml        # Master deployment orchestration
├── deploy/environments/        # dev.yaml, prod.yaml cluster configs
├── deploy/values/              # Per-service values (backend, frontend, postgres, pgweb, hasura)
├── charts/frontend/            # Frontend Helm chart
├── charts/backend/             # Backend Helm chart
├── charts/hasura/              # Hasura GraphQL engine Helm chart
├── hasura/                     # Hasura project configuration
│   ├── migrations/             # Database schema migrations (up.sql/down.sql)
│   └── metadata/               # Declarative Hasura configuration (tables, permissions)
├── workspace/
│   ├── apps/backend/           # Express server, Dockerfiles
│   ├── apps/frontend/          # React app, Dockerfiles, Vite config
│   └── packages/lib/           # Shared TypeScript library
└── Tiltfile                    # Dev iteration configuration
```

---

## Database Schema

From `table_creation.sql`:

| Table | Purpose |
|-------|---------|
| `users` | User accounts (id, email, name) |
| `nodes` | DAG vertices - tasks or logic gates |
| `edges` | DAG edges - parent-child relationships |

**Node types**:
- `task`: Regular todo with `value` (boolean completion)
- `logic`: AND/OR/NOT/XOR gate with `logic_type`

---

## Development Commands

```bash
tilt up                    # Start dev environment with hot reload

helmfile -e dev apply      # Deploy to dev cluster
helmfile -e prod apply     # Deploy to prod cluster
helmfile -e prod diff      # Preview prod changes
```

---

## Image Registry

- Frontend: `shiukaheng/todo-frontend`
- Backend: `shiukaheng/todo-backend`

---

## Preferences

- **Declarative approach preferred**: Configuration, infrastructure, and application logic should be declarative where possible (e.g., Kubernetes manifests, Helm values, Terraform, declarative API responses)

---

## Agent Instructions

**When making changes to this project, update AGENTS.md if you:**

1. Add new technologies, libraries, or frameworks
2. Change architecture decisions or patterns
3. Complete major features or components
4. Modify deployment, CI/CD, or dev workflow
5. Add new environment configurations
6. Change database schema or add migrations
7. Introduce new services or microservices

**Keep sections updated:**
- Update "Current Status" when features are completed
- Update "Tech Stack" when adding dependencies
- Update "Key Files" when adding important new files
- Update "Development Commands" when adding new scripts/workflows

---

## Notes for Future Development

### Database Priorities
1. **Hasura migrations setup**: Create initial migration from schema
2. **Migration workflow**: Decide between init container, manual job, or Hasura console
3. **Schema evolution**: Plan for incremental migrations (up.sql/down.sql pattern)

### Backend Priorities (With Hasura)
- Backend may be minimized or removed - CRUD handled by Hasura
- If kept: Custom business logic, DAG computation, auth webhooks
- Consider: Client-side DAG computation instead of backend

### Hasura Priorities
1. Add Hasura Helm chart to deployment
2. Configure metadata (tables, relationships, permissions)
3. Set up GraphQL subscriptions for real-time updates
4. Plan authentication integration (JWT or webhook)

### Frontend Priorities
1. Create todo list UI components
2. Add DAG visualization (suggested: React Flow)
3. Implement GraphQL client (Apollo Client or urql)
4. Add forms for node/edge creation

### Shared Lib Priorities
1. Define TypeScript types for User, Node, Edge
2. Add GraphQL schema types
3. Create GraphQL queries/mutations
