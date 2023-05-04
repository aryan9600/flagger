#!/usr/bin/env bash

set -o errexit

LINKERD_VER="stable-2.13.2"
LINKERD_SMI_VER="0.2.0"
REPO_ROOT=$(git rev-parse --show-toplevel)

mkdir -p ${REPO_ROOT}/bin

curl -SsL https://github.com/linkerd/linkerd2/releases/download/${LINKERD_VER}/linkerd2-cli-${LINKERD_VER}-linux-amd64 > ${REPO_ROOT}/bin/linkerd
chmod +x ${REPO_ROOT}/bin/linkerd
curl -SsL https://github.com/linkerd/linkerd-smi/releases/download/v${LINKERD_SMI_VER}/linkerd-smi-${LINKERD_SMI_VER}-linux-amd64 > ${REPO_ROOT}/bin/linkerd-smi
chmod +x ${REPO_ROOT}/bin/linkerd-smi

echo ">>> Installing Linkerd ${LINKERD_VER}"
${REPO_ROOT}/bin/linkerd install --crds | kubectl apply -f -
${REPO_ROOT}/bin/linkerd install | kubectl apply -f -
${REPO_ROOT}/bin/linkerd check

echo ">>> Installing Linkerd SMI"
${REPO_ROOT}/bin/linkerd-smi install | kubectl apply -f -
${REPO_ROOT}/bin/linkerd-smi check

echo ">>> Installing Linkerd Viz"
${REPO_ROOT}/bin/linkerd viz install | kubectl apply -f -
kubectl -n linkerd-viz rollout status deploy/prometheus
${REPO_ROOT}/bin/linkerd viz check

echo '>>> Installing Flagger'
kubectl apply -k ${REPO_ROOT}/kustomize/linkerd

kubectl -n flagger-system set image deployment/flagger flagger=test/flagger:latest
kubectl -n flagger-system rollout status deployment/flagger
