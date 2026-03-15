# -*- mode: Python -*-

# Build frontend with live update
docker_build(
    "frontend",
    context="apps/frontend",
    dockerfile="apps/frontend/Dockerfile",
    live_update=[
        sync("apps/frontend/src", "/app/src"),
    ],
)

# Build backend with live update
docker_build(
    "backend",
    context="apps/backend",
    dockerfile="apps/backend/Dockerfile",
    live_update=[
        sync("apps/backend/src", "/app/src"),
    ],
)

# Deploy from existing Helm charts
k8s_yaml(local("helm template frontend charts/frontend --set image.repository=frontend"))
k8s_yaml(local("helm template backend charts/backend --set image.repository=backend"))

# Port forwards for local access
k8s_resource("frontend", port_forwards="5173:80")
k8s_resource("backend", port_forwards="3000:3000")
