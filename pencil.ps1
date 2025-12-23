param(
    [ValidateSet('dot','erase','write','status')]
    [string]$command,

    [string]$name
)

# -----------------------------
# Paths
# -----------------------------
$pencil = Join-Path $HOME '.graphite'
$jsonPath = Join-Path $pencil 'graphites.json'

if (-not (Test-Path $jsonPath)) {
    Write-Host "Missing graphites.json at $jsonPath" -ForegroundColor Red
    exit 1
}

$graphites = Get-Content $jsonPath -Raw | ConvertFrom-Json

# -----------------------------
# Optional single-graphite filter
# -----------------------------
if ($name) {
    $graphites = $graphites | Where-Object {
        $_.Name -ieq $name -or
        $_.Get  -ieq $name -or
        $_.Got  -ieq $name
    }

    if (-not $graphites) {
        Write-Host "No graphite found matching '$name'" -ForegroundColor Red
        exit 1
    }
}

# -----------------------------
# Helpers
# -----------------------------
function Resolve-TargetPath {
param ($path)

    if ([System.IO.Path]::IsPathRooted($path)) {
        return $path
    }

    return Join-Path $HOME $path
}

function Get-LinkStatus {
param ($path)

    if (-not (Test-Path $path)) {
        return 'MISSING'
    }

    $item = Get-Item $path -Force
    if ($item.LinkType -eq 'SymbolicLink') {
        return 'LINKED'
    }

    return 'NOT LINKED'
}

# -----------------------------
# Commands
# -----------------------------
switch ($command) {

    # Copy system → graphite repo
    'dot' {
        foreach ($graphite in $graphites) {

            $source = Resolve-TargetPath $graphite.Path
            $dest   = Join-Path $pencil $graphite.Get

            if (-not (Test-Path $source)) {
                Write-Host "No Charcoal of $($graphite.Name)" -ForegroundColor Red
                continue
            }

            if (Test-Path $dest) {
                Write-Host "Already a Graphite $($graphite.Name)" -ForegroundColor Green
                continue
            }

            Write-Host "Copying Charcoal of $($graphite.Name)"

            if ($graphite.dir) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                Copy-Item $source $dest -Recurse -Force
            }
            else {
                Copy-Item $source $dest -Force
            }
        }
    }

    # Remove system files
    'erase' {
        foreach ($graphite in $graphites) {

            $target = Resolve-TargetPath $graphite.Path

            if (Test-Path $target) {
                Remove-Item $target -Recurse -Force
                Write-Host "Erased $($graphite.Name)"
            }
            else {
                Write-Host "No Graphite of $($graphite.Name)" -ForegroundColor Yellow
            }
        }
    }

    # Link graphite repo → system
    'write' {
        foreach ($graphite in $graphites) {

            $source = Join-Path $pencil $graphite.Get
            $target = Resolve-TargetPath $graphite.Path

            if (-not (Test-Path $source)) {
                Write-Host "No Graphite found for $($graphite.Name)" -ForegroundColor Red
                continue
            }

            $parent = Split-Path $target
            if ($parent -and -not (Test-Path $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
            Write-Host "Created Pencil $($graphite.Get) → $target" -ForegroundColor Green
        }
    }

    # Show status
    'status' {
        foreach ($graphite in $graphites) {

            $target = Resolve-TargetPath $graphite.Path
            $repo   = Join-Path $pencil $graphite.Get

            $linkStatus = Get-LinkStatus $target
            $repoStatus = if (Test-Path $repo) { 'PUSHED' } else { 'NOT PUSHED' }

            $color = switch ($linkStatus) {
                'LINKED'     { 'Green' }
                'NOT LINKED' { 'Yellow' }
                'MISSING'    { 'DarkGray' }
            }

            "{0,-20} {1,-12} {2}" -f `
            $graphite.Get,
            $linkStatus,
            $repoStatus |
            Write-Host -ForegroundColor $color
        }
    }
}
