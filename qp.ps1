    # Find all .qd files in the current directory
    $files = Get-ChildItem -Path . -Filter "*.qd" -File | Select-Object -ExpandProperty FullName

    if (-not $files) {
        Write-Host "No .qd files found."
        return
    }

    if ($files.Count -eq 1) {
        $file = $files
    } else {
        # Let user choose from fzf if more than one file
        $file = $files | fzf
    }

    if ($file) {
        dx quarkdown compile $file -p -w
    } else {
        Write-Host "No file selected."
    }
