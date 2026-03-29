# -*- mode: Python -*-
def helmfile(file):
  watch_file(file)
  return local("helmfile -f %s template | grep -v -e '^Decrypting .*' | grep -v -e '^Fetching .*' | grep -v 'as it is not a table.$'" % file)

k8s_yaml(helmfile("deploy/helmfile.yaml"))

# Base infrastructure
k8s_resource(
  workload='postgres-postgresql',
)

# Web UI for database
k8s_resource(
  workload='pgweb',
  port_forwards=8092,
  resource_deps=['postgres-postgresql']
)

# Backend API
docker_build('shiukaheng/todo-backend', 'workspace', dockerfile="workspace/apps/backend/Dockerfile")
k8s_resource(
  workload='backend',
  resource_deps=['postgres-postgresql']
)

# Frontend React app
docker_build('shiukaheng/todo-frontend', 'workspace', dockerfile="workspace/apps/frontend/Dockerfile")
k8s_resource(
  workload='frontend',
  port_forwards=8090,
  resource_deps=['backend']
)

# Hasura GraphQL Engine
k8s_resource(
  workload='hasura-graphql-engine',
  port_forwards=8091,
  resource_deps=['postgres-postgresql']
)
