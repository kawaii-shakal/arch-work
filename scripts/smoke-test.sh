#!/bin/bash
set -euo pipefail

runuser -u user -- zsh -lic '
    set -e
    cd "$HOME"
    for tool in nload ncdu ansible ssh dig ipcalc nslookup mise go golangci-lint terraform kubectl argocd; do
        command -v "$tool"
    done
    ansible --version
    go version
    [[ -z "$(go env GOBIN)" && ":$PATH:" == *":$HOME/go/bin:"* ]]
    golangci-lint version
    CHECKPOINT_DISABLE=1 terraform version
    kubectl version --client
    argocd version --client
    [[ -n "${POWERLEVEL9K_MODE:-}" ]]
'
