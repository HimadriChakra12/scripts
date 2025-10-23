    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$VMName,

        [string]$ISO,
        [string]$OSType,
        [string]$Type = "gui",
        [string]$json
    )

    switch ($Command.ToLower()) {
        "types" {
            VBoxManage list ostypes
        }
        "start"     { if ($VMName) { VBoxManage startvm "$VMName" --type=$Type } else { Write-Host "Missing VM name." } }
        "stop"      { if ($VMName) { VBoxManage controlvm "$VMName" acpipowerbutton } else { Write-Host "Missing VM name." } }
        "poweroff"  { if ($VMName) { VBoxManage controlvm "$VMName" poweroff } else { Write-Host "Missing VM name." } }
        "list"      { VBoxManage list vms }
        "info"      { if ($VMName) { VBoxManage showvminfo "$VMName" } else { Write-Host "Missing VM name." } }
        "delete"    { if ($VMName) { VBoxManage unregistervm "$VMName" --delete } else { Write-Host "Missing VM name." } }
        "create" {
            if ($json) {
                if (-not (Test-Path $json)) {
                    Write-Host "??? JSON file '$json' not found."
                    return
                }

                $config = Get-Content $json | ConvertFrom-Json
                $VMName  = $config.name
                $ISO     = $config.iso
                $OSType  = $config.ostype
                $Memory  = $config.memory
                $VRAM    = $config.vram
                $DiskMB  = $config.disk
            } else {
                if (-not ($VMName -and $ISO)) {
                    Write-Host "??? Usage: vb create <VMName> <ISOPath> [OSType] or -json <file>"
                    return
                }
                if (-not $OSType) {
                    Write-Host "`n???? Available OS Types:`n"
                    VBoxManage list ostypes | Select-String -Pattern "ID:|Description:" | ForEach-Object { $_.ToString() }
                    $OSType = Read-Host "`n???? Enter the OS type ID (e.g., Ubuntu_64, Windows10_64)"
                }
                $Memory = 2048
                $VRAM = 16
                $DiskMB = 20000
            }

            $vmsDir = "$env:USERPROFILE\VirtualBox VMs\$VMName"
            $vdiPath = "$vmsDir\$VMName.vdi"

            VBoxManage createvm --name "$VMName" --ostype "$OSType" --register
            VBoxManage modifyvm "$VMName" --memory $Memory --vram $VRAM --audio none --boot1 dvd --nic1 nat
            VBoxManage createhd --filename "$vdiPath" --size $DiskMB
            VBoxManage storagectl "$VMName" --name "SATA Controller" --add sata --controller IntelAhci
            VBoxManage storageattach "$VMName" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$vdiPath"
            VBoxManage storageattach "$VMName" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "$ISO"

            Write-Host "`n??? VM '$VMName' created with type '$OSType'. You can now run: vb start '$VMName'"
        }

        default {
            Write-Host "Usage:"
            Write-Host "  vb list"
            Write-Host "  vb start <VM> [-Type gui|headless]"
            Write-Host "  vb stop <VM>"
            Write-Host "  vb poweroff <VM>"
            Write-Host "  vb info <VM>"
            Write-Host "  vb delete <VM>"
            Write-Host "  vb create <VM> <ISO> [OSType]"
            Write-Host "  vb create -json <file>       # JSON-based VM creation"
            Write-Host "  vb types                     # list available OS types"
        }
    }
}
