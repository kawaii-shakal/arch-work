$ErrorActionPreference = 'Stop'

$checksumUrl = 'https://mirror.pkgbuild.com/wsl/latest/archlinux.wsl.SHA256'
$curl = Get-Command curl -CommandType Application | Select-Object -First 1
$checksum = & $curl.Source -fsSL --retry 3 --max-time 30 $checksumUrl
if ($LASTEXITCODE -ne 0 -or $checksum -notmatch '^([0-9a-f]{64})\s+\*?archlinux\.wsl\s*$') {
    throw "Could not read the official Arch WSL SHA-256 checksum."
}
$baseHash = $Matches[1]

$output = Join-Path $PSScriptRoot 'dist'
docker buildx build --platform linux/amd64 --no-cache --progress plain `
    --build-arg "ARCH_WSL_SHA256=$baseHash" `
    --output "type=local,dest=$output" $PSScriptRoot
if ($LASTEXITCODE -ne 0) {
    throw "Arch-Work build failed."
}

$image = Get-Item -LiteralPath (Join-Path $output 'arch-work.wsl')
Write-Host ('{0} ({1:N0} MiB)' -f $image.FullName, ($image.Length / 1MB))
