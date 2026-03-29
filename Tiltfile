# -*- mode: Python -*-
load('ext://uibutton', 'cmd_button')

def helmfile(file):
  watch_file(file)
  return local("helmfile -f %s template | grep -v -e '^Decrypting .*' | grep -v -e '^Fetching .*' | grep -v 'as it is not a table.$'" % file)

# Clean up leftover failed/error pods from previous runs (e.g. helm test hooks)
local_resource(
  'cleanup-failed-pods',
  cmd='kubectl delete pods --field-selector=status.phase=Failed -n default --ignore-not-found',
  labels=['infra'],
)

# Button to fully reset persistent state (deletes PVCs — PostgreSQL data will be wiped)
cmd_button(
  'reset-volumes',
  argv=['kubectl', 'delete', 'pvc', '--all', '-n', 'default', '--ignore-not-found'],
  text='Reset Volumes (wipe DB)',
  icon_name='delete_forever',
  resource='cleanup-failed-pods',
)

watch_file('charts/')
k8s_yaml(helmfile("deploy/helmfile.yaml"))

# Base infrastructure
k8s_resource(
  workload='postgres-postgresql',
  port_forwards=15432,
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

# GraphiQL IDE (connects to Hasura at localhost:8091)
k8s_resource(
  workload='graphiql',
  port_forwards=8093,
  resource_deps=['hasura-graphql-engine']
)
