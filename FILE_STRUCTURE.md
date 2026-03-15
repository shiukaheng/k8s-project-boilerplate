# FILE_STRUCTURE.md

## Overview

This document describes a layered architecture for building and deploying TypeScript applications to Kubernetes. The system progresses from source code to production deployment through six distinct layers, each with a clear responsibility.

---

# Part 1: The Six Layers

## Mental Model

Think of this system as a **progression of abstractions**:

```
Source Code → Container Images → Kubernetes Packaging → Environment Orchestration → Dev Iteration → Production Delivery
```

Each layer transforms the output of the previous layer into something closer to a running production system.

---

## Layer 1: Source Code (npm Workspaces)

### Role
Organize your TypeScript frontend and backend code in a monorepo structure that enables code sharing, unified dependency management, and atomic commits across services.

### Mental Understanding
This is your "application layer" — the actual software you're building. npm workspaces let you:
- Share types and utilities between frontend and backend
- Run builds and tests across all packages with one command
- Keep dependencies in sync

### Key Insight
The monorepo is not about deployment — it's about **developer experience** and **code organization**. Deployment concerns are handled by later layers.

---

## Layer 2: Container Images (Dockerfiles)

### Role
Define how each service becomes a reproducible, distributable container image.

### Mental Understanding
Each Dockerfile is a **build recipe** that answers:
- What runtime does this service need?
- How do I build the TypeScript?
- What's the minimal environment needed to run it?

### Key Insight
Dockerfiles live next to their source code (`apps/backend/Dockerfile`) because they're part of the service definition, not infrastructure. They should produce **production-ready images** — minimal, secure, optimized.

---

## Layer 3: Helm Charts (Your Services)

### Role
Package each service as a reusable, configurable Kubernetes deployment unit.

### Mental Understanding
A Helm chart answers: **"How does this service run on Kubernetes?"**

It defines:
- Deployments (how many replicas, what image)
- Services (how to reach the pods)
- ConfigMaps (configuration data)
- Ingress (HTTP routing, if applicable)

### Key Insight
**Helm charts are environment-agnostic.** They define *how* a service runs, not *where* or *with what configuration*. A single chart can deploy to dev, staging, or prod — the differences are injected via values.

### Sane Defaults Pattern
Your charts should work standalone with sensible defaults:
```yaml
# charts/backend/values.yaml
database:
  mode: sqlite        # works without external dependencies
  sqlite:
    path: /data/app.db
```

This lets developers `helm install backend ./charts/backend` and have a working service immediately.

---

## Layer 4: Environment Orchestration (Helmfile)

### Role
Declare what gets deployed together, in which environments, with what configuration.

### Mental Understanding
Helmfile is your **cluster composer**. It answers:
- What services make up this system?
- What external dependencies are needed (databases, queues, ingress)?
- How does configuration differ between dev and prod?

### Key Insight
Helmfile sits **above** your charts. While charts define individual services, Helmfile defines the **whole system**:

```yaml
releases:
  - name: backend         # your chart
  - name: frontend        # your chart
  - name: postgresql      # external chart (bitnami)
  - name: redis           # external chart (bitnami)
  - name: ingress-nginx   # cluster infrastructure
```

### Environment Separation

```
environments/
  dev.yaml    → cluster-wide dev settings (domain, tags, flags)
  prod.yaml   → cluster-wide prod settings

values/
  backend/
    common.yaml   → shared across all envs
    dev.yaml       → dev-specific overrides
    prod.yaml      → prod-specific overrides
```

---

## Layer 5: Dev Iteration (Tilt)

### Role
Provide fast feedback loop during development with live reload, port forwarding, and temporary image builds.

### Mental Understanding
Tilt is your **development accelerator**. It:
- Watches your source files for changes
- Rebuilds images incrementally
- Syncs code into running containers (live update)
- Port-forwards services to localhost
- Shows logs and status in a unified UI

### Key Insight
**Tilt is only for development.** It builds temporary images, loads them into your dev cluster, and provides the fast iteration loop you need while coding. It does not:
- Push images to registries
- Produce production artifacts
- Deploy to production clusters

---

## Layer 6: Production Delivery (CI/CD)

### Role
Build, version, and deploy production artifacts.

### Mental Understanding
This is your **release pipeline**. It answers:
- How do images get built and pushed to a registry?
- How do we version images (git SHA, semver)?
- How do we deploy to production?

### Key Insight
**CI/CD is the bridge between "code merged" and "code running in production."** While Tilt handles the dev inner loop, CI/CD handles the production outer loop.

### Typical Flow
```
Push to main
    ↓
CI builds images (docker build)
    ↓
CI pushes images with version tag (docker push)
    ↓
CI updates Helm values with new tag
    ↓
CI runs helmfile apply
    ↓
Production updated
```

---

# Part 2: Directory Structure

```
myapp-monorepo/
│
├── apps/                              # Layer 1: Source Code
│   ├── frontend/                       # Frontend service (TypeScript)
│   │   ├── src/
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── Dockerfile                  # Layer 2: Container Image
│   │
│   └── backend/                       # Backend service (TypeScript)
│       ├── src/
│       ├── package.json
│       ├── tsconfig.json
│       └── Dockerfile                  # Layer 2: Container Image
│
├── charts/                             # Layer 3: Helm Charts
│   ├── frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml                 # Sane defaults, works standalone
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── configmap.yaml
│   │
│   └── backend/
│       ├── Chart.yaml
│       ├── values.yaml                 # Defaults to sqlite, no external deps
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           └── secret.yaml
│
├── deploy/                             # Layer 4: Environment Orchestration
│   │
│   ├── helmfile.yaml                  # Master orchestration file
│   │
│   ├── environments/                 # Cluster-wide settings per environment
│   │   │   ├── dev.yaml
│   │   │   └── prod.yaml
│   │
│   └── values/                        # Per-release values overrides
│       ├── frontend/
│       │   ├── common.yaml
│       │   ├── dev.yaml
│       │   └── prod.yaml
│       │
│       ├── backend/
│       │   ├── common.yaml
│       │   ├── dev.yaml
│       │   └── prod.yaml
│       │
│       ├── postgresql/              # External dependency config
│       │   └── prod.yaml
│       │
│       └── redis/                    # External dependency config
│           └── prod.yaml
│
├── tilt/                               # Layer 5: Dev Iteration
│   ├── Tiltfile                        # Dev orchestration
│   └── .tiltignore
│
├── scripts/                            # Layer 6: Build/Publish utilities
│   ├── build.sh                        # Build all images
│   ├── push.sh                         # Push images to registry
│   └── deploy.sh                       # Helmfile wrapper
│
├── .github/                            # Layer 6: CI/CD
│   └── workflows/
│       ├── ci.yaml                     # Build, test, lint on PR
│       └── release.yaml                # Build, push, deploy on merge
│
├── infra/                              # Optional: Cloud infrastructure
│   └── terraform/                      # Managed services, DNS, etc.
│
├── package.json                        # npm workspaces root
├── package-lock.json
├── tsconfig.base.json                  # Shared TypeScript config
├── Makefile                            # Convenient command wrappers
└── README.md
```

---

# Layer Summary Table

| Layer | Directory | Tool | Purpose |
|-------|-----------|------|--------|
| 1 | `apps/` | npm workspaces | Source code organization |
| 2 | `apps/*/Dockerfile` | Docker | Container image definitions |
| 3 | `charts/` | Helm | Kubernetes packaging |
| 4 | `deploy/` | Helmfile | Environment orchestration |
| 5 | `tilt/` | Tilt | Dev iteration loop |
| 6 | `scripts/`, `.github/` | CI/CD | Production delivery |

---

# Key Principles

## Separation of Concerns

- **Source code** lives in `apps/`
- **Packaging** lives in `charts/`
- **Orchestration** lives in `deploy/`
- **Dev tooling** lives in `tilt/`
- **Build scripts** live in `scripts/`

## Environment-Agnostic Charts

Helm charts in `charts/` should:
- Work standalone with sane defaults
- Not hardcode environment-specific values
- Accept configuration through values files

## Configuration Flow

```
charts/*/values.yaml           # Chart defaults (works standalone)
        ↓
deploy/values/*/common.yaml    # Environment-shared overrides
        ↓
deploy/values/*/dev.yaml       # Environment-specific overrides
        ↓
deploy/environments/*.yaml     # Cluster-wide context
        ↓
Final rendered manifest
```

## Dev vs Prod Separation

| Concern | Dev | Prod |
|---------|-----|------|
| Image builds | Tilt (temporary) | CI/CD (versioned) |
| Image registry | Local only | Container registry |
| Deploy trigger | `tilt up` | Git push / merge |
| Configuration | `values/*/dev.yaml` | `values/*/prod.yaml` |

---

# Quick Commands

```bash
# Development
tilt up                          # Start dev environment

# Manual builds (Layer 6)
make build TAG=$(git rev-parse --short HEAD)
make push TAG=$(git rev-parse --short HEAD)

# Deployment
helmfile -e dev apply            # Deploy to dev
helmfile -e prod apply           # Deploy to prod
helmfile -e prod diff            # Preview changes
```

---

# When to Add What

| Need | Add to |
|------|--------|
| New microservice | `apps/newservice/` + `charts/newservice/` |
| New external dependency | `deploy/helmfile.yaml` (new release) + `deploy/values/dependency/` |
| New environment | `deploy/environments/staging.yaml` + `deploy/values/*/staging.yaml` |
| Build optimization | `apps/*/Dockerfile` |
| Dev experience improvement | `tilt/Tiltfile` |
| CI/CD changes | `.github/workflows/` or `scripts/` |
