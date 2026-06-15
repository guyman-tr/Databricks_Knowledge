param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Wrapper   = Join-Path $ScriptDir "poll_and_report.ps1"

$Tasks = @(
    @{ Name = "CryptoNopAuditPoll04"; Time = "04:00"; Tag = "0400" },
    @{ Name = "CryptoNopAuditPoll09"; Time = "09:00"; Tag = "0900" }
)

function Remove-IfExists {
    param([string]$Name)
    $existing = Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $Name -Confirm:$false
    }
}

if ($Uninstall) {
    foreach ($t in $Tasks) {
        Write-Host "Removing task '$($t.Name)'..."
        Remove-IfExists $t.Name
    }
    Write-Host "Done. Tasks removed."
    exit 0
}

if (-not (Test-Path $Wrapper)) {
    throw "Wrapper script missing: $Wrapper"
}

foreach ($t in $Tasks) {
    Write-Host "Installing task '$($t.Name)' at $($t.Time) (tag='$($t.Tag)')..."

    Remove-IfExists $t.Name

    # Use the native ScheduledTasks PowerShell module. Each parameter is a
    # proper PS object, so no shell-escape quoting headaches.
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Wrapper`" -Tag $($t.Tag)"
    $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
    $trigger   = New-ScheduledTaskTrigger -Daily -At $t.Time
    $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
                                              -DontStopIfGoingOnBatteries `
                                              -StartWhenAvailable `
                                              -ExecutionTimeLimit ([TimeSpan]::FromMinutes(30))
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

    Register-ScheduledTask -TaskName $t.Name `
                           -Action $action `
                           -Trigger $trigger `
                           -Settings $settings `
                           -Principal $principal `
                           -Description "Snapshot SP_Crypto_NOP upstream sources for source-drift audit." `
                           -Force | Out-Null

    Write-Host "  -> registered."
}

Write-Host ""
Write-Host "All tasks installed."
Write-Host "Verify with:"
Write-Host "  Get-ScheduledTask -TaskName CryptoNopAudit* | Select-Object TaskName,State,@{n='NextRun';e={(Get-ScheduledTaskInfo `$_).NextRunTime}}"
Write-Host ""
Write-Host "Logs land in tools\sp_crypto_nop_audit\logs\<date>.log"
Write-Host "Reports land in tools\sp_crypto_nop_audit\reports\ AND C:\Users\guyman\Downloads\"
Write-Host ""
Write-Host "To uninstall: powershell -File `"$($MyInvocation.MyCommand.Path)`" -Uninstall"
