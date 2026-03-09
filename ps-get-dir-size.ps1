#Requires -Version 5.0
<#
.SYNOPSIS
Analyzes disk space usage on a specified network or local path.

.DESCRIPTION
Enumerates all top-level subdirectories within a path, calculates their total size,
and displays the top 100 largest directories.

.EXAMPLE
.\Get-DirectorySize.ps1
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

# Prompt for network path
Write-Host "Directory Size Analyzer" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

$path = Read-Host "Enter the path to analyze (e.g., \\server\share or C:\Users)"

# Validate path
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

# Collect directory sizes
$directoryList = @()
$errorCount = 0

try {
    $topLevelFolders = @(Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue)

    if ($topLevelFolders.Count -eq 0) {
        Write-Host "No subdirectories found in the specified path." -ForegroundColor Yellow
        exit 0
    }

    $totalFolders = $topLevelFolders.Count
    $processedFolders = 0

    foreach ($folder in $topLevelFolders) {
        $processedFolders++

        try {
            # Calculate size of directory
            $files = @(Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue)
            $size = ($files | Measure-Object -Property Length -Sum).Sum

            if ($null -eq $size) {
                $size = 0
            }

            $formattedSize = Format-Size -Bytes $size
            Write-Host "[$processedFolders/$totalFolders] $($folder.Name): $formattedSize" -ForegroundColor Gray

            # Add to collection
            $directoryList += [PSCustomObject]@{
                FullPath  = $folder.FullName
                Name      = $folder.Name
                SizeBytes = $size
            }
        }
        catch {
            $errorCount++
            Write-Host "[$processedFolders/$totalFolders] $($folder.Name): [Access Denied]" -ForegroundColor Yellow

            # Still add to collection with 0 size
            $directoryList += [PSCustomObject]@{
                FullPath  = $folder.FullName
                Name      = $folder.Name
                SizeBytes = 0
            }
        }
    }
}
catch {
    Write-Host "Error accessing path: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Sort by size (descending) and take top 100
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Top 100 Largest Directories" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$topDirectories = $directoryList | Sort-Object -Property SizeBytes -Descending | Select-Object -First 100

# Create formatted table
$tableData = $topDirectories | ForEach-Object {
    [PSCustomObject]@{
        'Directory'      = $_.Name
        'Full Path'      = $_.FullPath
        'Size (GB)'      = [string]::Format("{0:N2}", $_.SizeBytes / 1GB)
        'Size (MB)'      = [string]::Format("{0:N2}", $_.SizeBytes / 1MB)
        'Size (Bytes)'   = $_.SizeBytes
    }
}

# Display the table
$tableData | Format-Table -Property Directory, 'Size (GB)', 'Size (MB)' -AutoSize -Wrap

# Summary statistics
Write-Host ""
Write-Host "Summary Statistics:" -ForegroundColor Green
$totalSize = ($directoryList | Measure-Object -Property SizeBytes -Sum).Sum
Write-Host "Total size of all subdirectories: $(Format-Size -Bytes $totalSize)"
Write-Host "Number of subdirectories scanned: $totalFolders"
Write-Host "Errors encountered: $errorCount"
