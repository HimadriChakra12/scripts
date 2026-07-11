<#
.SYNOPSIS
    Simple File Organizer for Windows PowerShell 5.1

.DESCRIPTION
    Organizes files in a directory into folders based on file extension.

.EXAMPLE
    .\organize.ps1 -Path "C:\Users\IT\Downloads"
#>

param(
    [string]$Path = (Get-Location).Path
)

# Verify path exists
if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "[ERROR] Path not found: $Path" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Organizing files in: $Path" -ForegroundColor Cyan
Write-Host ""

# File categories
$Categories = @{
    Documents = @(
        ".pdf",".doc",".docx",".txt",".rtf",".odt",
        ".xls",".xlsx",".ppt",".pptx"
    )

    Images = @(
        ".jpg",".jpeg",".png",".gif",".bmp",".tif",
        ".tiff",".svg",".webp"
    )

    Videos = @(
        ".mp4",".mkv",".avi",".mov",".wmv",".flv",".webm"
    )

    Audio = @(
        ".mp3",".wav",".ogg",".flac",".m4a",".aac"
    )

    Archives = @(
        ".zip",".rar",".7z",".tar",".gz",".iso"
    )

    Installers = @(
        ".exe",".msi",".bat",".cmd"
    )

    Code = @(
        ".ps1",".psm1",".psd1",
        ".py",".c",".cpp",".cs",".go",
        ".js",".ts",".html",".css",
        ".json",".xml",".lua",".php"
    )
}

# Create folders
foreach ($Folder in $Categories.Keys) {

    $Destination = Join-Path $Path $Folder

    if (-not (Test-Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory | Out-Null
    }
}

# Create Others folder
$Others = Join-Path $Path "Others"

if (-not (Test-Path $Others)) {
    New-Item -Path $Others -ItemType Directory | Out-Null
}

# Get files only from top level
$Files = Get-ChildItem -LiteralPath $Path -File -Force

foreach ($File in $Files) {

    $Extension = $File.Extension.ToLower()
    $Moved = $false

    foreach ($Category in $Categories.Keys) {

        if ($Categories[$Category] -contains $Extension) {

            $Destination = Join-Path $Path $Category

            try {
                Move-Item -LiteralPath $File.FullName `
                          -Destination $Destination `
                          -Force `
                          -ErrorAction Stop

                Write-Host "[OK] $($File.Name) -> $Category" -ForegroundColor Green
            }
            catch {
                Write-Host "[FAILED] $($File.Name): $($_.Exception.Message)" -ForegroundColor Red
            }

            $Moved = $true
            break
        }
    }

    if (-not $Moved) {

        try {
            Move-Item -LiteralPath $File.FullName `
                      -Destination $Others `
                      -Force `
                      -ErrorAction Stop

            Write-Host "[OTHER] $($File.Name)" -ForegroundColor Yellow
        }
        catch {
            Write-Host "[FAILED] $($File.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Organization complete!" -ForegroundColor Cyan
