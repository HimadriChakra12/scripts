<#
.SYNOPSIS
  Simple File Organizer
.DESCRIPTION
  Sorts files in a directory into subfolders by type.
.EXAMPLE
  ./organize.ps1 -Path "C:\Users\IT\Downloads"
#>

param(
    [string]$Path = (Get-Location)
)

if (-not (Test-Path $Path)) {
    Write-Host "❌ Path not found: $Path" -ForegroundColor Red
    exit
}

Write-Host "📂 Organizing files in: $Path" -ForegroundColor Cyan

# Define folder categories
$categories = @{
    "Documents" = @(".pdf", ".doc", ".docx", ".txt", ".odt", ".rtf", ".xls", ".xlsx", ".ppt", ".pptx")
    "Images"    = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".svg", ".webp")
    "Videos"    = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm")
    "Audio"     = @(".mp3", ".wav", ".ogg", ".flac", ".m4a")
    "Archives"  = @(".zip", ".rar", ".7z", ".tar", ".gz", ".iso")
    "Installers"= @(".exe", ".msi", ".bat", ".cmd")
    "Code"      = @(".ps1", ".py", ".c", ".cpp", ".go", ".js", ".html", ".css", ".lua", ".json", ".xml")
}

# Create category folders if they don’t exist
foreach ($folder in $categories.Keys) {
    $dest = Join-Path $Path $folder
    if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
}

# Move files
$files = Get-ChildItem -Path $Path -File
foreach ($file in $files) {
    $ext = $file.Extension.ToLower()
    $moved = $false
    foreach ($category in $categories.GetEnumerator()) {
        if ($category.Value -contains $ext) {
            $target = Join-Path $Path $category.Key
            Move-Item -Path $file.FullName -Destination $target -Force
            Write-Host "✔ $($file.Name) → $($category.Key)" -ForegroundColor Green
            $moved = $true
            break
        }
    }
    if (-not $moved) {
        $misc = Join-Path $Path "Others"
        if (-not (Test-Path $misc)) { New-Item -ItemType Directory -Path $misc | Out-Null }
        Move-Item -Path $file.FullName -Destination $misc -Force
        Write-Host "• $($file.Name) → Others" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Done organizing files!" -ForegroundColor Cyan

