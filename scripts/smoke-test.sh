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

runuser -u user -- bash -se <<'SSH_TEST'
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
key="$fixture/test-key"
export HOME="$fixture/home"
ssh-keygen -q -t ed25519 -N '' -f "$key"
printf '%s\n' "$key" | arch-work-import-ssh
test "$(stat -c '%a' "$HOME/.ssh/test-key")" = 600
test "$(sha256sum < "$key")" = "$(sha256sum < "$HOME/.ssh/test-key")"
printf 'existing\n' > "$HOME/.ssh/test-key"
printf '%s\n' "$key" | arch-work-import-ssh
test "$(cat "$HOME/.ssh/test-key")" = existing
SSH_TEST
