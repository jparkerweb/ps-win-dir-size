# Architecture

> Part of [AGENTS.md](../AGENTS.md) — project guidance for AI coding agents.

## Script Flow

```
1. INITIALIZATION
   └─ Display header

2. RESUME CHECK
   ├─ Scan .\state\ for *.json files with Status = "InProgress"
   ├─ If found: show numbered list, prompt to resume or start new
   └─ If none found (or user presses Enter): prompt for new path

3. PATH VALIDATION  (new scan only)
   ├─ Verify path exists (Test-Path)
   └─ Verify path is directory (PSIsContainer check)

4. SCAN SETUP
   ├─ New scan:    enumerate top-level folders, create state file (.\state\dirscan-<ts>.json)
   └─ Resume:      load results + pending folders from state; drop deleted pending paths

5. DIRECTORY ENUMERATION
   └─ For each folder:
      ├─ Recursively calculate size (Get-ChildItem -Recurse -File)
      ├─ Sum file lengths (Measure-Object)
      ├─ Capture LastWriteTime as LastModified
      ├─ Display progress (colored console output)
      ├─ Catch DirectoryNotFoundException → [Deleted], not an error
      ├─ Catch other errors → [Access Denied], errorCount++
      └─ Persist state to JSON after every folder

6. SCAN COMPLETION
   └─ Update state file: Status = "Complete", CompletedAt = now

7. RESULTS PROCESSING
   ├─ Sort by size (descending)
   ├─ Select top 100 largest
   └─ Transform into display format (includes Last Modified column)

8. OUTPUT & SUMMARY
   ├─ Format and display table (Format-Table)
   └─ Print summary statistics
```

## Core Components

### Format-Size Function
**Purpose:** Convert raw byte counts to human-readable format.

```powershell
Format-Size -Bytes 1048576  # Returns "1.00 MB"
```

**Logic:** Bytes < 1 MB → KB | Bytes < 1 GB → MB | Otherwise → GB

### State Management Functions
| Function | Purpose |
|---|---|
| `Get-StateDirectory` | Returns `$PSScriptRoot\state\`, creating it if needed |
| `Get-IncompleteScans` | Reads all `*.json` state files; returns those with `Status = "InProgress"` |
| `New-ScanState` | Creates and immediately writes a new state file; returns `{State, FilePath}` |
| `Save-ScanState` | Serializes the state hashtable to JSON; called after every folder |
| `Show-ResumptionMenu` | Displays numbered incomplete-scan list; returns selected entry or `$null` |

**State file schema:** `.\state\dirscan-<YYYYMMDD-HHmmss>.json`
- `Status`: `"InProgress"` | `"Complete"`
- `Results`: accumulated completed entries (grows each iteration)
- `PendingFolders`: full paths not yet scanned (shrinks each iteration)
- `ProcessedCount`, `ErrorCount`, `TotalFolders`: running counters

### Input & Validation
- Resume prompt shown when `Status = "InProgress"` files exist in `.\state\`
- New scan: interactive `Read-Host` → `Test-Path` → `PSIsContainer` check → exit 1 on failure
- Resume: `Test-Path` on `TargetPath`; deleted pending folders silently dropped, `TotalFolders` adjusted

### Directory Scanning Loop
- Uses `Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue` (non-blocking, non-exclusive)
- Captures `$folder.LastWriteTime` as `LastModified` on each successful entry
- Three catch tiers:
  - `[System.IO.DirectoryNotFoundException]` → `[Deleted]` in gray; skipped from results, not an error
  - `catch` (other) → `[Access Denied]` in yellow; added with `SizeBytes = 0`; `$errorCount++`
- `Save-ScanState` called after every folder (success, deleted, or error)

### Output Formatting
- Sorts by `SizeBytes` descending, top 100
- `Format-Table` columns: `Directory`, `Size (GB)`, `Size (MB)`, `Last Modified` (`yyyy-MM-dd`)
- On resume, pre-loaded results from state merge with newly-scanned results before sort

## Data Flow

```
Header Display
    ↓
Scan .\state\ for InProgress files
    ├─ Found → Show resume menu → user picks number or Enter
    └─ None (or Enter) → prompt for new path
    ↓
Path Validation / Resume State Load
    ↓
New scan: enumerate folders → write state file
Resume:   load Results + PendingFolders, drop deleted paths
    ↓
For Each Folder:
  Size Calculation → Capture LastModified → Progress Output
  → Error Handling (Deleted / AccessDenied / Success)
  → Save-ScanState (persists after every folder)
    ↓
Mark state Complete
    ↓
Merge pre-loaded + newly-scanned results
    ↓
Sort & Filter (top 100 by SizeBytes)
    ↓
Table Formatting (Directory, Size GB/MB, Last Modified)
    ↓
Console Output + Summary Statistics
```

## Error Handling Strategy

1. **Path-level errors**: `Test-Path` / `PSIsContainer` checks; exit with code 1
2. **Enumeration errors** (outer `catch`): Catch and report; exit with code 1
3. **Deleted folder mid-scan** (`[System.IO.DirectoryNotFoundException]`): Log as `[Deleted]`; skip from results; not an error
4. **Per-folder access errors** (inner `catch`): Mark as `[Access Denied]`; add with size 0; increment error count
5. **Null/empty size checks**: Empty folders return `$null` from `Measure-Object`; normalized to 0
6. **Resume path gone**: `Test-Path` on `TargetPath` at resume time; exit 1 with clear message
7. **Pending folder deleted before resume**: `Test-Path` per entry; silently dropped, count adjusted

This layered approach ensures:
- Critical errors stop execution
- Partial access is not fatal
- All accessible directories are reported
- Interrupted scans are recoverable without re-scanning completed work
