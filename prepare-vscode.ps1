$ErrorActionPreference = 'Stop'

$version = @(code --version)
if ($LASTEXITCODE -ne 0 -or $version.Count -lt 2 -or $version[1] -notmatch '^[a-f0-9]{40}$') {
    throw 'Could not find the version of VS Code Stable in Windows.'
}
$commit = $version[1]
$extension = code --locate-extension ms-vscode-remote.remote-wsl
if ($LASTEXITCODE -ne 0 -or -not $extension -or -not (Test-Path -LiteralPath (Join-Path $extension 'scripts/wslDownload.sh') -PathType Leaf)) {
    throw 'Install the WSL extension in Windows VS Code first.'
}

$prepare = @'
set -euo pipefail
commit=$1
installer=$(wslpath -u "$2")
bin="$HOME/.vscode-server/bin"
target="$bin/$commit"
if [[ -x "$target/node" && -x "$target/bin/code-server" ]]; then
    echo "VS Code Server is already prepared for $commit."
    exit 0
fi
if [[ -e "$target" || -L "$target" ]]; then
    echo "An incomplete server already exists. Connect from VS Code to repair it." >&2
    exit 1
fi

mkdir -p -- "$bin"
stage=$(mktemp -d "$bin/.arch-work.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT
archive="$stage/server.tar.gz"
curl --fail --silent --show-error --location --retry 2 --connect-timeout 15 --max-time 180 \
    --output "$archive" "https://update.code.visualstudio.com/commit:$commit/server-linux-x64/stable"
# Use the installed WSL extension's own installer in a staging folder.
VSCODE_SERVER_TAR="$archive" /bin/sh "$installer" "$commit" stable "$stage/servers"
test -x "$stage/servers/$commit/bin/code-server"
"$stage/servers/$commit/node" --version
mv -nT -- "$stage/servers/$commit" "$target"
test -x "$target/bin/code-server"
echo "VS Code Server is ready for $commit."
'@

wsl --distribution Arch-Work --user user --cd '~' --exec /bin/bash -c $prepare prepare-vscode $commit (Join-Path $extension 'scripts/wslDownload.sh')
if ($LASTEXITCODE -ne 0) {
    throw 'VS Code Server preparation failed. VS Code can still install it when connecting.'
}
