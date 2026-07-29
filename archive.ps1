param(
    [string]$BuildDirectory = "build"
)

$ErrorActionPreference = "Stop"

$sdkRoot = (Get-Location).Path
$buildPath = [System.IO.Path]::GetFullPath((Join-Path $sdkRoot $BuildDirectory))

$packages = @(
  "packages/optimizely-cms-sdk",
  "packages/optimizely-cms-cli"
)

Write-Host "SDK root: $sdkRoot"
Write-Host "Build directory: $buildPath"

if (Test-Path $buildPath) {
    Write-Host "Cleaning build directory..."
    Remove-Item -Path $buildPath -Recurse -Force
}

New-Item -Path $buildPath -ItemType Directory -Force | Out-Null

foreach ($package in $packages) {
    $packagePath = Join-Path $sdkRoot $package

    if (-not (Test-Path $packagePath)) {
        throw "Package directory does not exist: $packagePath"
    }

    $packageJsonPath = Join-Path $packagePath "package.json"

    if (-not (Test-Path $packageJsonPath)) {
        throw "package.json does not exist: $packageJsonPath"
    }

    Write-Host "Building $package..."

    pnpm --dir $packagePath build

    if ($LASTEXITCODE -ne 0) {
        throw "pnpm build failed for $package"
    }

    Write-Host "Packing $package..."

    pnpm --dir $packagePath pack --pack-destination $buildPath

    if ($LASTEXITCODE -ne 0) {
        throw "pnpm pack failed for $package"
    }
}

Write-Host ""
Write-Host "Created tarballs:"
Get-ChildItem -Path $buildPath -Filter "*.tgz" |
    Select-Object -ExpandProperty FullName
