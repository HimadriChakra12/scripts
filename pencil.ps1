param(
    [string]$command
)

$pencil = "$HOME/.graphite"
$graphites = Get-Content "$HOME/.graphite/graphites.json" -Raw | ConvertFrom-Json

switch ($command) {

    'dot' {
        foreach ($graphite in $graphites) {

            $destination = Join-Path $pencil $graphite.Get
            $mkd         = Join-Path $pencil $graphite.Got

            if (Test-Path $graphite.Path) {

                if (Test-Path $destination) {
                    Write-Host "Already a Graphite $($graphite.Name)" -ForegroundColor Green
                }
                else {
                    Write-Host "Copying Charcoal of $($graphite.Name)"

                    if ($graphite.dir) {
                        if (-not (Test-Path $mkd)) {
                            New-Item -ItemType Directory -Path $mkd | Out-Null
                        }
                        Copy-Item $graphite.Path $destination -Recurse -Force
                    }
                    else {
                        Copy-Item $graphite.Path $destination -Force
                    }
                }
            }
            else {
                Write-Host "No Charcoal of $($graphite.Name)" -ForegroundColor Red
            }
        }

        Write-Host "Making graphite has completed" -ForegroundColor Cyan
    }

    'erase' {
        foreach ($graphite in $graphites) {
            if (Test-Path $graphite.Path) {
                Remove-Item $graphite.Path -Recurse -Force
            }
            else {
                Write-Host "No Graphite of $($graphite.Name)" -ForegroundColor Red
            }
        }
    }

    'write' {
        foreach ($graphite in $graphites) {

            $sourcePath = Join-Path $pencil $graphite.Get
            $targetPath = $graphite.Path

            if (Test-Path $sourcePath) {
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
                Write-Host "Created Pencil $($graphite.Get) → $targetPath" -ForegroundColor Green
            }
            else {
                Write-Host "No Graphite found for $targetPath" -ForegroundColor Red
            }
        }
    }

    default {
        Write-Host "Unknown command: $command" -ForegroundColor Yellow
    }
}
