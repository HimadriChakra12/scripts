# 1. Fuzzy find the Go file
$file = Get-ChildItem -Recurse -Filter "*.go" | ForEach-Object { $_.FullName } | fzf
if (-not $file) {
    Write-Host "No file selected."
    exit
}

# 2. Determine output executable name
$exeName = [System.IO.Path]::GetFileNameWithoutExtension($file) + ".exe"
$exePath = Join-Path -Path (Split-Path $file) -ChildPath $exeName

# 3. Remove existing exe if it exists
if (Test-Path $exePath) {
    Remove-Item $exePath -Force
    Write-Host "Removed existing executable: $exeName"
}

# 3.5 Check dependencies
Write-Host "Checking dependencies..."
go mod tidy

# 4. Compile the Go file and capture output/errors
Write-Host "Compiling $file..."
try {
    $buildOutput = & go build -o $exePath $file 2>&1
    Set-Clipboard -Value ($buildOutput -join "`n")
} catch {
    Write-Host "Compilation failed with error:"
    Write-Host $_
    Set-Clipboard -Value $_.ToString()
    write-host "$buildOutput"
    exit
}

# 5. Check if exe exists
if (Test-Path $exePath) {
    Write-Host "Compilation successful! Executable: $exePath"
    if ($buildOutput) { Write-Host "Build messages copied to clipboard." }
} else {
    Write-Host "Compilation failed."
    if ($buildOutput) { Write-Host "Build messages copied to clipboard." }
}
