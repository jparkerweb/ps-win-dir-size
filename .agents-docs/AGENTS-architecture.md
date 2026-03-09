# Architecture

> Part of [AGENTS.md](../AGENTS.md) — project guidance for AI coding agents.

## Script Flow

```
1. INITIALIZATION
   └─ Display header & prompt user for path

2. PATH VALIDATION
   ├─ Verify path exists (Test-Path)
   └─ Verify path is directory (PSIsContainer check)

3. DIRECTORY ENUMERATION
   ├─ Get all top-level folders (Get-ChildItem -Directory)
   └─ For each folder:
      ├─ Recursively calculate size (Get-ChildItem -Recurse -File)
      ├─ Sum file lengths (Measure-Object)
      ├─ Display progress (colored console output)
      └─ Catch access-denied errors & continue

4. RESULTS PROCESSING
   ├─ Sort by size (descending)
   ├─ Select top 100 largest
   └─ Transform into display format

5. OUTPUT & SUMMARY
   ├─ Format and display table (Format-Table)
   └─ Print summary statistics
```

## Core Components

### Format-Size Function (lines 16-28)
**Purpose:** Convert raw byte counts to human-readable format

```powershell
Format-Size -Bytes 1048576  # Returns "1.00 MB"
```

**Logic:**
- Bytes < 1 MB → Show in KB
- Bytes < 1 GB → Show in MB
- Otherwise → Show in GB

**Usage:** Applied to every size calculation for display; uses `-f` (Format operator) pattern.

### Input & Validation (lines 30-47)
- Interactive `Read-Host` prompt
- `Test-Path` validates existence
- `Get-Item` with `PSIsContainer` check ensures it's a directory
- Exits with status code 1 on validation failure

### Directory Scanning Loop (lines 68-101)
- Iterates through top-level folders
- Uses `Get-ChildItem -Recurse -File` for comprehensive size calculation
- Handles null size results (converts to 0)
- Wraps in try-catch for per-folder error resilience
- Increments error counter for summary

**Key design pattern:** `-ErrorAction SilentlyContinue` allows the loop to continue even if one directory is inaccessible; errors are caught at the folder level, not the command level.

### Output Formatting (lines 115-129)
- Sorts by `SizeBytes` descending
- Takes top 100 results
- Transforms into PSCustomObject with display columns
- Uses `Format-Table` for aligned output

## Data Flow

```
User Input
    ↓
Path Validation
    ↓
Top-Level Folder Enumeration
    ↓
For Each Folder:
  Size Calculation → Progress Output → Error Handling
    ↓
Aggregated Directory List
    ↓
Sort & Filter (top 100)
    ↓
Table Formatting
    ↓
Console Output
```

## Error Handling Strategy

1. **Path-level errors** (lines 38-46): Prevent execution; exit with code 1
2. **Enumeration errors** (lines 103-105): Catch and report; exit with code 1
3. **Per-folder errors** (lines 90-100): Catch individually; mark as `[Access Denied]`; continue loop
4. **Null/empty checks** (lines 76-78): Handle edge cases (empty folders)

This layered approach ensures:
- Critical errors stop execution
- Partial access is not fatal
- All accessible directories are reported
