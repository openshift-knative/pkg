#!/bin/bash

set -Eeuo pipefail

branch=${1-'knative-v0.22.0'}
openshift=${2-'4.7'}
promotion_disabled=${3-false}

if [[ "$branch" == "knative-next" ]]; then
  branch="knative-nightly"
fi

cat <<EOF
tag_specification:
  cluster: https://api.ci.openshift.org
  name: '$openshift'
  namespace: ocp
promotion:
  additional_images:
    knative-eventing-kafka-src: src
  disabled: $promotion_disabled
  cluster: https://api.ci.openshift.org
  namespace: openshift
  name: $branch
base_images:
  base:
    name: '$openshift'
    namespace: ocp
    tag: base
build_root:
  project_image:
    dockerfile_path: openshift/ci-operator/build-image/Dockerfile
canonical_go_repository: knative.dev/eventing-kafka
binary_build_commands: make
test_binary_build_commands: make
tests:
- as: e2e-aws-ocp-${openshift//./}
  steps:
    cluster_profile: aws
    test:
    - as: test
      cli: latest
      commands: make test
      from: src
      resources:
        requests:
          cpu: 100m
    workflow: ipi-aws
- as: e2e-aws-ocp-${openshift//./}-continuous
  cron: 0 */12 * * 1-5
  steps:
    cluster_profile: aws
    test:
    - as: test
      cli: latest
      commands: make test
      from: src
      resources:
        requests:
          cpu: 100m
    workflow: ipi-aws
resources:
  '*':
    limits:
      memory: 6Gi
    requests:
      cpu: 4
      memory: 6Gi
  'bin':
    limits:
      memory: 6Gi
    requests:
      cpu: 4
      memory: 6Gi
images:
EOF
