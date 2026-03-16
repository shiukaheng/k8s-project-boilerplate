# -*- mode: Python -*-

# Build frontend with dev Dockerfile
docker_build(
    "frontend",
    context="workspace",
    dockerfile="workspace/apps/frontend/Dockerfile.dev",
    live_update=[
        sync("workspace/apps/frontend/src", "/workspace/apps/frontend/src"),
        sync("workspace/packages/lib/src", "/workspace/packages/lib/src"),
    ],
)

# Build backend with dev Dockerfile
docker_build(
    "backend",
    context="workspace",
    dockerfile="workspace/apps/backend/Dockerfile.dev",
    live_update=[
        sync("workspace/apps/backend/src", "/workspace/apps/backend/src"),
        sync("workspace/packages/lib/src", "/workspace/packages/lib/src"),
    ],
)

# Deploy from existing Helm charts with dev tag
k8s_yaml(local("helm template frontend charts/frontend --set image.tag=dev"))
k8s_yaml(local("helm template backend charts/backend --set image.tag=dev"))

# Port forwards for local access
k8s_resource("frontend", port_forwards="5173:80")
k8s_resource("backend", port_forwards="3000:3000")
