# -*- mode: Python -*-
def helmfile(file):
  return local("helmfile -f %s template | grep -v -e '^Decrypting .*' | grep -v -e '^Fetching .*' | grep -v 'as it is not a table.$'" % file)

k8s_yaml(helmfile("deploy/helmfile.yaml"))