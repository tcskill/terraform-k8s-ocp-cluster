#!/usr/bin/env bash

OUT_FILE="$1"

OUT_DIR=$(dirname "${OUT_FILE}")
mkdir -p "${OUT_DIR}"

set -e

INGRESS_SUBDOMAIN=$(oc get deployment router-default -n openshift-ingress -o yaml | \
  yq r - 'spec.template.spec.containers[0].env(name==ROUTER_CANONICAL_HOSTNAME).value')

echo "Found ingress subdomain: ${INGRESS_SUBDOMAIN}"
echo -n "${INGRESS_SUBDOMAIN}" > "${OUT_FILE}"
