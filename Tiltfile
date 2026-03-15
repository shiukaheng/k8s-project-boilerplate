# -*- mode: Python -*-

# Build frontend with dev Dockerfile
docker_build(
    "frontend",
    context="apps/frontend",
    dockerfile="apps/frontend/Dockerfile.dev",
    live_update=[
        sync("apps/frontend/src", "/app/src"),
    ],
)

# Build backend with dev Dockerfile
docker_build(
    "backend",
    context="apps/backend",
    dockerfile="apps/backend/Dockerfile.dev",
    live_update=[
        sync("apps/backend/src", "/app/src"),
    ],
)

# Deploy from existing Helm charts with dev tag
k8s_yaml(local("helm template frontend charts/frontend --set image.tag=dev"))
k8s_yaml(local("helm template backend charts/backend --set image.tag=dev"))

# Port forwards for local access
k8s_resource("frontend", port_forwards="5173:80")
k8s_resource("backend", port_forwards="3000:3000")
