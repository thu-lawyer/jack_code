# jack_code Auto Sync Script
# Syncs every 1 hour

param(
    [string]$RepoPath = "$PSScriptRoot"
)

function Write-ColorOutput {
    param([string]$Message, [string]$Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Info" { Write-Host "[$timestamp] [INFO] " -ForegroundColor Blue -NoNewline; Write-Host $Message }
        "Success" { Write-Host "[$timestamp] [SUCCESS] " -ForegroundColor Green -NoNewline; Write-Host $Message }
        "Warning" { Write-Host "[$timestamp] [WARNING] " -ForegroundColor Yellow -NoNewline; Write-Host $Message }
        "Error" { Write-Host "[$timestamp] [ERROR] " -ForegroundColor Red -NoNewline; Write-Host $Message }
    }
}

function Sync-ToGitHub {
    param([string]$Path)
    Push-Location $Path
    try {
        $status = git status --porcelain
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-ColorOutput "No changes to commit" "Info"
            return $true
        }
        Write-ColorOutput "Detected changes:" "Info"
        $statusLines = $status -split "`n"
        $displayLines = $statusLines | Select-Object -First 10
        foreach ($line in $displayLines) { Write-Host "  $line" }
        if ($statusLines.Count -gt 10) { Write-Host "  ... and $($statusLines.Count - 10) more files" }
        
        git add . 2>&1 | Out-Null
        $commitMsg = "Auto sync: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $commitResult = git commit -m $commitMsg 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Commit successful: $commitMsg" "Success"
        } else {
            Write-ColorOutput "Commit failed or no changes" "Warning"
            return $false
        }
        Write-ColorOutput "Pushing to GitHub..." "Info"
        $pushResult = git push 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Push completed" "Success"
            return $true
        } else {
            Write-ColorOutput "Push failed: $pushResult" "Error"
            return $false
        }
    } catch {
        Write-ColorOutput "Error during sync: $_" "Error"
        return $false
    } finally {
        Pop-Location
    }
}

Write-Host "============================================================"
Write-Host "jack_code Auto Sync - Every 1 Hour"
Write-Host "============================================================"
Write-ColorOutput "Monitoring: $RepoPath" "Success"
Write-ColorOutput "Interval: 3600 seconds (1 hour)" "Success"
Write-Host "------------------------------------------------------------"
Write-Host ""
Write-ColorOutput "Auto sync started, press Ctrl+C to stop" "Info"
Write-Host ""

$count = 0
$IntervalSeconds = 3600

try {
    while ($true) {
        $count++
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$currentTime] Check #$count"
        Sync-ToGitHub -Path $RepoPath
        Write-ColorOutput "Next check in 1 hour" "Info"
        Write-Host "------------------------------------------------------------"
        Write-Host ""
        Start-Sleep -Seconds $IntervalSeconds
    }
} catch {
    Write-Host ""
    Write-ColorOutput "Stopping..." "Info"
    Write-ColorOutput "Total checks performed: $count" "Success"
}