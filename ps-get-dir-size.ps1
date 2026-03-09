#Requires -Version 5.0
<#
.SYNOPSIS
Analyzes disk space usage on a specified network or local path.

.DESCRIPTION
Enumerates all top-level subdirectories within a path, calculates their total size,
and displays the top 100 largest directories. Supports resuming interrupted scans
via JSON state files persisted to .\state\.

.EXAMPLE
.\ps-get-dir-size.ps1
#>

param()

function Format-Size {
    param([long]$Bytes)

    if ($Bytes -lt 1MB) {
        return [string]::Format("{0:N2} KB", $Bytes / 1KB)
    }
    elseif ($Bytes -lt 1GB) {
        return [string]::Format("{0:N2} MB", $Bytes / 1MB)
    }
    else {
        return [string]::Format("{0:N2} GB", $Bytes / 1GB)
    }
}

function Get-StateDirectory {
    $stateDir = Join-Path $PSScriptRoot "state"
    if (-not (Test-Path -Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir | Out-Null
    }
    return $stateDir
}

function Get-IncompleteScans {
    $stateDir = Get-StateDirectory
    $incompleteScans = @()

    Get-ChildItem -Path $stateDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $content = Get-Content -Path $_.FullName -Raw -ErrorAction Stop
            $parsed = $content | ConvertFrom-Json
            if ($parsed.Status -eq "InProgress") {
                $incompleteScans += [PSCustomObject]@{
                    State    = $parsed
                    FilePath = $_.FullName
                }
            }
        }
        catch {
            # Skip malformed or unreadable state files
        }
    }

    return $incompleteScans
}

function New-ScanState {
    param(
        [string]$Path,
        [string[]]$PendingFolders
    )

    $stateDir    = Get-StateDirectory
    $timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
    $leafName    = Split-Path -Path $Path -Leaf
    $stateFilePath = Join-Path $stateDir "$leafName-dirscan-$timestamp.json"

    $state = @{
        Version        = "1.0"
        Status         = "InProgress"
        TargetPath     = $Path
        StartedAt      = (Get-Date -Format "o")
        CompletedAt    = $null
        TotalFolders   = $PendingFolders.Count
        ProcessedCount = 0
        ErrorCount     = 0
        Results        = @()
        PendingFolders = $PendingFolders
    }

    Save-ScanState -State $state -StateFilePath $stateFilePath

    return [PSCustomObject]@{
        State    = $state
        FilePath = $stateFilePath
    }
}

function Save-ScanState {
    param(
        [hashtable]$State,
        [string]$StateFilePath
    )

    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $StateFilePath -Encoding UTF8
}

function Show-ResumptionMenu {
    param([array]$IncompleteScans)

    Write-Host "Incomplete scans found:" -ForegroundColor Yellow
    Write-Host ""

    for ($i = 0; $i -lt $IncompleteScans.Count; $i++) {
        $scan = $IncompleteScans[$i]
        $startedAt = [datetime]::Parse($scan.State.StartedAt).ToString("yyyy-MM-dd HH:mm")
        Write-Host "  [$($i + 1)] $($scan.State.TargetPath)  ($($scan.State.ProcessedCount)/$($scan.State.TotalFolders) folders, started $startedAt)" -ForegroundColor Cyan
    }

    Write-Host ""
    $choice = Read-Host "Enter number to resume, or press Enter for a new scan"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return $null
    }

    $index = 0
    if ([int]::TryParse($choice, [ref]$index) -and $index -ge 1 -and $index -le $IncompleteScans.Count) {
        return $IncompleteScans[$index - 1]
    }

    Write-Host "Invalid selection. Starting a new scan." -ForegroundColor Yellow
    return $null
}

# ── Header ──────────────────────────────────────────────────────────────────
Write-Host "Directory Size Analyzer" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# ── Resume prompt ────────────────────────────────────────────────────────────
$incompleteScans = Get-IncompleteScans
$isResuming      = $false
$state           = $null
$stateFilePath   = $null

if ($incompleteScans.Count -gt 0) {
    $selected = Show-ResumptionMenu -IncompleteScans $incompleteScans
    if ($null -ne $selected) {
        $isResuming = $true

        # Convert PSCustomObject from JSON into a mutable hashtable
        $state = @{}
        $selected.State.PSObject.Properties | ForEach-Object { $state[$_.Name] = $_.Value }
        $state.PendingFolders = @($state.PendingFolders)
        $state.Results        = @($state.Results)
        $stateFilePath        = $selected.FilePath
    }
}

# ── Scan setup ───────────────────────────────────────────────────────────────
$directoryList = @()
$errorCount    = 0

if ($isResuming) {
    $path = $state.TargetPath

    if (-not (Test-Path -Path $path)) {
        Write-Host "Error: Resumed scan target '$path' no longer exists or is not accessible." -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Resuming scan of: $path" -ForegroundColor Green
    Write-Host ""

    # Pre-populate results from already-completed work
    $directoryList = @($state.Results | ForEach-Object {
        [PSCustomObject]@{
            FullPath     = $_.FullPath
            Name         = $_.Name
            SizeBytes    = [long]$_.SizeBytes
            LastModified = $_.LastModified
        }
    })

    # Validate pending folders — silently drop any that were deleted
    $validPending = @($state.PendingFolders | Where-Object { Test-Path -Path $_ })
    $droppedCount = $state.PendingFolders.Count - $validPending.Count
    if ($droppedCount -gt 0) {
        Write-Host "Note: $droppedCount folder(s) no longer exist and will be skipped." -ForegroundColor DarkGray
    }

    $topLevelFolders  = @($validPending | ForEach-Object { Get-Item -Path $_ -ErrorAction SilentlyContinue } | Where-Object { $_ })
    $processedFolders = [int]$state.ProcessedCount
    $totalFolders     = $processedFolders + $topLevelFolders.Count
    $errorCount       = [int]$state.ErrorCount

    $state.TotalFolders   = $totalFolders
    $state.PendingFolders = $validPending
}
else {
    $path = Read-Host "Enter the path to analyze (e.g., \\server\share or C:\Users)"

    if (-not (Test-Path -Path $path)) {
        Write-Host "Error: Path '$path' does not exist or is not accessible." -ForegroundColor Red
        exit 1
    }

    $pathItem = Get-Item -Path $path
    if ($pathItem.PSIsContainer -eq $false) {
        Write-Host "Error: Path '$path' is not a directory." -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Scanning directories in: $path" -ForegroundColor Green
    Write-Host ""
}

# ── Scan loop ────────────────────────────────────────────────────────────────
try {
    if (-not $isResuming) {
        $topLevelFolders = @(Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue)

        if ($topLevelFolders.Count -eq 0) {
            Write-Host "No subdirectories found in the specified path." -ForegroundColor Yellow
            exit 0
        }

        $totalFolders     = $topLevelFolders.Count
        $processedFolders = 0

        $pendingPaths  = @($topLevelFolders | ForEach-Object { $_.FullName })
        $newScanResult = New-ScanState -Path $path -PendingFolders $pendingPaths
        $state         = $newScanResult.State
        $stateFilePath = $newScanResult.FilePath
    }

    foreach ($folder in $topLevelFolders) {
        $processedFolders++

        try {
            $files = @(Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue)
            $size  = ($files | Measure-Object -Property Length -Sum).Sum

            if ($null -eq $size) { $size = 0 }

            $formattedSize = Format-Size -Bytes $size
            Write-Host "[$processedFolders/$totalFolders] $($folder.Name): $formattedSize" -ForegroundColor Gray

            $directoryList += [PSCustomObject]@{
                FullPath     = $folder.FullName
                Name         = $folder.Name
                SizeBytes    = $size
                LastModified = $folder.LastWriteTime.ToString("o")
            }
        }
        catch [System.IO.DirectoryNotFoundException] {
            # Folder deleted mid-scan — skip it, not an error
            Write-Host "[$processedFolders/$totalFolders] $($folder.Name): [Deleted]" -ForegroundColor DarkGray
        }
        catch {
            $errorCount++
            Write-Host "[$processedFolders/$totalFolders] $($folder.Name): [Access Denied]" -ForegroundColor Yellow

            $directoryList += [PSCustomObject]@{
                FullPath     = $folder.FullName
                Name         = $folder.Name
                SizeBytes    = 0
                LastModified = $null
            }
        }

        # Persist state after every folder
        $state.PendingFolders = @($state.PendingFolders | Where-Object { $_ -ne $folder.FullName })
        $state.Results        = @($directoryList | ForEach-Object {
            @{
                FullPath     = $_.FullPath
                Name         = $_.Name
                SizeBytes    = $_.SizeBytes
                LastModified = $_.LastModified
            }
        })
        $state.ProcessedCount = $processedFolders
        $state.ErrorCount     = $errorCount
        Save-ScanState -State $state -StateFilePath $stateFilePath
    }
}
catch {
    Write-Host "Error accessing path: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Mark scan complete
$state.Status      = "Complete"
$state.CompletedAt = (Get-Date -Format "o")
Save-ScanState -State $state -StateFilePath $stateFilePath

# ── Results ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Top 100 Largest Directories" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$topDirectories = $directoryList | Sort-Object -Property SizeBytes -Descending | Select-Object -First 100

$tableData = $topDirectories | ForEach-Object {
    [PSCustomObject]@{
        'Directory'     = $_.Name
        'Full Path'     = $_.FullPath
        'Size (GB)'     = [string]::Format("{0:N2}", $_.SizeBytes / 1GB)
        'Size (MB)'     = [string]::Format("{0:N2}", $_.SizeBytes / 1MB)
        'Size (Bytes)'  = $_.SizeBytes
        'Last Modified' = if ($_.LastModified) { [datetime]::Parse($_.LastModified).ToString("yyyy-MM-dd") } else { "" }
    }
}

$tableData | Format-Table -Property Directory, 'Size (GB)', 'Size (MB)', 'Last Modified' -AutoSize -Wrap

# Summary statistics
Write-Host ""
Write-Host "Summary Statistics:" -ForegroundColor Green
$totalSize = ($directoryList | Measure-Object -Property SizeBytes -Sum).Sum
Write-Host "Total size of all subdirectories: $(Format-Size -Bytes $totalSize)"
Write-Host "Number of subdirectories scanned: $totalFolders"
Write-Host "Errors encountered: $errorCount"
