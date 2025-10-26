# tsk.ps1 - Task manager

# Get processes
$processes = Get-Process | Select-Object Id, ProcessName, CPU, WS

# Add MemoryMB property
$processes | ForEach-Object {
    $_ | Add-Member -MemberType NoteProperty -Name MemoryMB -Value ([math]::Round($_.WS / 1MB, 2))
}

# Prepare display list
$displayList = $processes | ForEach-Object {
    "$($_.Id)`t$($_.ProcessName)"
}

# --- FIX START ---
# Define the core PowerShell command for the preview, using triple-quotes for clarity.
# Note: The backticks are necessary here to escape the double quotes for the external command.

# FZF with preview
$selected = $displayList | fzf `
    --prompt "Select process: " `
    --height 50% `
    --layout=reverse `
    --border `
# --- FIX END ---

if (-not $selected) {
    Write-Host "No process selected."
    exit
}

# Extract process ID
$procId = ($selected -split "\s+")[0]

# Ask for action
$action = Read-Host "Enter action: [k]ill / [c]ancel"

if ($action -eq 'k') {
    Stop-Process -Id $procId -Force
    Write-Host "Process $procId killed."
} else {
    Write-Host "Cancelled."
}
