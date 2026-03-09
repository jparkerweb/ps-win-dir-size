# ps-get-dir-size

A PowerShell script for analyzing disk space usage on local and network paths. Quickly identify which top-level subdirectories consume the most storage space.

<img src="ps-win-dir-size.jpg" width="800">

## Features

- **Network Path Support** - Works with both local and network paths (SMB shares)
- **Progressive Output** - Shows real-time progress as directories are scanned
- **Access Denied Handling** - Gracefully continues scanning if access is denied to specific folders
- **Top 100 Summary** - Displays the largest directories ranked by size
- **Multiple Size Formats** - Shows sizes in bytes, MB, and GB for flexibility
- **Error Reporting** - Provides summary statistics on scan completion and errors encountered

## Requirements

- PowerShell 5.0 or higher
- Read access to the target path (or at least some subdirectories)
- For network paths: appropriate network access and permissions

## Usage

### Basic Usage

```powershell
.\ps-get-dir-size.ps1
```

The script will prompt you to enter the path to analyze:

```
Directory Size Analyzer
======================

Enter the path to analyze (e.g., \\server\share or C:\Users):
```

### Examples

**Analyze local drive:**
```powershell
C:\Users
```

**Analyze network share:**
```powershell
\\server\share
```

**Analyze specific folder:**
```powershell
C:\Program Files
```

## Output

The script provides two phases of output:

### 1. Progress Phase

As directories are scanned, you'll see real-time progress:

```
Scanning directories in: C:\Users

[1/5] Desktop: 2.45 GB
[2/5] Documents: 15.67 GB
[3/5] Downloads: 8.34 GB
[4/5] Music: 45.12 GB
[5/5] Videos: 234.56 GB
```

### 2. Final Summary

After scanning completes, the top 100 largest directories are displayed:

```
================================
Top 100 Largest Directories
================================

Directory           Size (GB)    Size (MB)
---------           ---------    ---------
Videos              234.56       240,230.40
Music               45.12        46,172.16
Documents          15.67        16,044.00
Downloads           8.34         8,540.16
Desktop             2.45         2,508.80

Summary Statistics:
Total size of all subdirectories: 306.14 GB
Number of subdirectories scanned: 5
Errors encountered: 0
```

## Error Handling

The script handles common errors gracefully:

- **Invalid Path** - Validates the path exists before scanning
- **Not a Directory** - Checks that the path is a directory, not a file
- **Access Denied** - Marks inaccessible folders as `[Access Denied]` and continues scanning
- **Network Issues** - Provides error messages for connectivity problems

If access is denied to a directory, it's still included in results with a size of 0 bytes.

## Performance

Scan time depends on:
- **Path Depth** - Deeper directory structures take longer
- **File Count** - More files = longer scan time
- **Network Latency** - Network shares are slower than local drives
- **Disk Performance** - SSD vs HDD differences apply

**Typical Performance:**
- Local drive (100 GB): 10-30 seconds
- Network share (100 GB): 30-120 seconds

## Troubleshooting

### "Access Denied" Errors

This is normal on network shares and Windows system folders. The script will continue scanning other directories. Use an account with broader permissions if you need access to protected folders.

### Path Not Found

Verify the path exists and is accessible:
```powershell
Test-Path "\\server\share"
```

### Script Won't Run

If you get an execution policy error:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteUigned -Scope CurrentUser
```

Then run the script again.

### No Subdirectories Found

The specified path has no subdirectories, or they're all inaccessible. Check path and permissions.

## Tips & Tricks

### Find and Remove Large Folders

After identifying large directories, you can manage them:

```powershell
# Get size of a specific folder
(Get-ChildItem -Path "\\server\share\LargeFolder" -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
```

### Run on Schedule

Create a Windows scheduled task to run the script weekly and save results:

```powershell
.\ps-get-dir-size.ps1 | Out-File "C:\Reports\disk-usage-$(Get-Date -Format yyyyMMdd).txt"
```

### Monitor Multiple Paths

Run the script multiple times with different paths and combine results for comprehensive analysis.

## Limitations

- Only analyzes immediate subdirectories (top-level folders)
- Does not include hidden files or system files that are inaccessible
- Size calculation based on file count; sparse files may show larger than actual disk usage
- Network timeouts may occur on very large or slow shares

## License

This script is provided as-is for administrative and troubleshooting purposes.

## Contributing

To report issues or suggest improvements, please document:
- The path being analyzed
- Any error messages displayed
- Expected vs actual results
- Your PowerShell version (`$PSVersionTable.PSVersion`)
