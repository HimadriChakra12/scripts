# lsx.ps1 — Enhanced ls/fd hybrid with tree recursion and search
[CmdletBinding()]
param(
    [string]$Path = '.',    # base folder or search pattern
    [switch]$a,             # show hidden/system
    [switch]$s,             # short/compact view
    [switch]$r,             # recursive listing
    [int]$dep = 1,          # recursion depth
    [switch]$d,             # only directories
    [switch]$f,             # only files
    [switch]$sum,           # summary totals
    [string]$p,             # search pattern
    [switch]$h              # help/usage
)

if ($h) {
    Write-Host @"
Usage: lsx [options] [path or pattern]

Options:
  -a       Show hidden and system files
  -s       Compact/short listing (like ls -1)
  -r       Recursive listing
  -dep N   Limit recursion depth (default 1)
  -d       Show only directories
  -f       Show only files
  -sum     Show totals (dirs, files, size)
  -p PAT   Filter by pattern (case-insensitive)
  -h       Show this usage message

Examples:
  lsx
  lsx -a -s
  lsx -r -dep 3
  lsx -p log
  lsx ps1
  lsx -f lua
  lsx -d config
"@
    return
}

# --- Smart argument detection ---
$searchPattern = $null
if ($p) {
    $searchPattern = $p
} elseif (-not (Test-Path $Path)) {
    $searchPattern = $Path
    $Path = "."
}

$currentPath = (Resolve-Path $Path).Path

# --- Detect git branch ---
$repoRoot = $null
$searchPath = $currentPath
while ($searchPath -ne [System.IO.Path]::GetPathRoot($searchPath)) {
    if (Test-Path (Join-Path $searchPath ".git")) {
        $repoRoot = $searchPath
        break
    }
    $searchPath = Split-Path $searchPath
}

$branch = ""
if ($repoRoot) {
    try {
        $headFile = Get-Content (Join-Path $repoRoot ".git\HEAD") -ErrorAction SilentlyContinue
        if ($headFile -match "ref: refs/heads/(.+)") {
            $branch = $Matches[1]
        }
    } catch { }
}

# --- Counters ---
$totalFiles = 0
$totalDirs  = 0
$totalSize  = 0

# --- Recursive display function ---
function Show-Items {
    param(
        [System.IO.FileSystemInfo[]]$Items,
        [int]$Level = 0
    )

    foreach ($item in $Items) {
        $indent = "  " * $Level
        $isDir = $item.PSIsContainer
        $isGitDir = $isDir -and ($item.Name -eq '.git')
        $ext = if (-not $isDir) { $item.Extension.ToLower() } else { '' }

        # Skip item if it doesn't match pattern (case-insensitive)
        if ($searchPattern) {
            if (-not ($item.Name -imatch $searchPattern)) { continue }
        }

        # Color by type
        $color = switch -Wildcard ($ext) {
            ".json" { "Yellow" }
            ".exe"  { "Red" }
            ".ps1"  { "Cyan" }
            ".lua"  { "DarkCyan" }
            ".go"   { "Blue" }
            ".c"    { "Magenta" }
            ".h"    { "DarkMagenta" }
            default {
                if ($isGitDir) { "DarkYellow" }
                elseif ($isDir) { "Green" }
                else { "Gray" }
            }
        }

        # Short view
        if ($s) {
            if ($isDir) {
                Write-Host ("{0}[DIR ] {1}" -f $indent, $item.Name) -ForegroundColor $color
            } elseif ($isGitDir) {
                Write-Host ("{0}<git> {1} .git" -f $indent, $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm")) -ForegroundColor $color
            } else {
                Write-Host ("{0}      {1}" -f $indent, $item.Name) -ForegroundColor $color
            }
        }
        else {
            $perm = if ($isDir) { 'd' } else { '-' }
            $perm += ($item.Attributes -match 'ReadOnly') ? 'r--' : 'rw-'
            $perm += ($item.Attributes -match 'Hidden') ? 'h--' : '---'
            $owner = (Get-Acl $item.FullName).Owner
            $size = if ($isGitDir) { '<git>' } elseif ($isDir) { '<DIR>' } else { '{0,8:N0}' -f ($item.Length) }
            $time = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Write-Host ("{0}{1,-25} {2,10} {3,16} {4}" -f $indent, $owner, $size, $time, $item.Name) -ForegroundColor $color
        }

        # Counters
        if ($isDir) { $script:totalDirs++ } else { $script:totalFiles++; $script:totalSize += $item.Length }

        # Recurse into directories
        if ($isDir -and $r -and ($Level + 1 -le $dep)) {
            $subItems = Get-ChildItem -LiteralPath $item.FullName -Force:$a -ErrorAction SilentlyContinue
            if ($d) { $subItems = $subItems | Where-Object { $_.PSIsContainer } }
            if ($f) { $subItems = $subItems | Where-Object { -not $_.PSIsContainer } }

            Show-Items -Items $subItems -Level ($Level + 1)
        }
    }
}

# --- Gather top-level items ---
$topItems = Get-ChildItem -LiteralPath $currentPath -Force:$a -ErrorAction SilentlyContinue
if ($d) { $topItems = $topItems | Where-Object { $_.PSIsContainer } }
if ($f) { $topItems = $topItems | Where-Object { -not $_.PSIsContainer } }

# --- Display header ---
Write-Host ""
if ($repoRoot -and $branch) {
    Write-Host ("[{0} ({1})]" -f $currentPath, $branch) -ForegroundColor DarkGray
} else {
    Write-Host ("[{0}]" -f $currentPath) -ForegroundColor DarkGray
}
Write-Host ""

# --- Show items recursively ---
Show-Items -Items $topItems -Level 0

# --- Summary ---
if ($sum) {
    Write-Host ""
    Write-Host ("{0} dirs, {1} files, {2:N0} KB total" -f $totalDirs, $totalFiles, ($totalSize / 1KB)) -ForegroundColor Yellow
}
Write-Host ""
