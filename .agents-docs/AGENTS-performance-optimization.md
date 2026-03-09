# Performance & Optimization

> Part of [AGENTS.md](../AGENTS.md) — project guidance for AI coding agents.

## Current Performance Characteristics

### Typical Scan Times
- **Local drive (100 GB)**: 10-30 seconds
- **Network share (100 GB)**: 30-120 seconds
- **Very large network shares (500+ GB)**: May exceed 2-3 minutes; risk of timeout

### Factors Affecting Performance
1. **Directory depth**: Recursive enumeration gets slower with nested structures
2. **File count**: Each file is enumerated; millions of small files slow scanning
3. **Network latency**: SMB protocol overhead multiplies with remote paths
4. **Disk speed**: SSD vs HDD differences apply to both local and cached network access
5. **Access control checks**: Each folder's permissions are evaluated

## Performance Bottlenecks

### Primary Bottleneck: Per-Folder Recursion
```powershell
Get-ChildItem -Path $folder.FullName -Recurse -File
```

**Issue:** For each top-level folder, this command recursively enumerates ALL files beneath it. On large folder trees, this is the dominant cost.

**Example impact:**
- Folder with 100k files → ~5-10 seconds on local drive
- Same folder on network → ~20-60 seconds
- 10 such folders → 50-100+ seconds total

### Secondary Bottleneck: Error Handling
Each folder wrapped in try-catch adds minor overhead. Acceptable for typical use; not the primary concern.

### Tertiary Bottleneck: Output Formatting
Sorting 1000s of results and table formatting is negligible compared to scanning.

## Optimization Opportunities

### 1. Parallel Processing (PowerShell 7+)
```powershell
$topLevelFolders | ForEach-Object -Parallel {
    Get-ChildItem -Path $_.FullName -Recurse -File | Measure-Object -Property Length -Sum
}
```
**Benefit**: Could reduce scan time by 50-70% on multi-core systems
**Trade-off**: Requires PowerShell 7+; current requirement is 5.0+
**Implementation**: Conditional based on `$PSVersionTable.PSVersion`

### 2. Depth Limiting
```powershell
Get-ChildItem -Path $folder.FullName -Recurse -File -Depth 10
```
**Benefit**: Skip very deep nested structures; faster for certain paths
**Trade-off**: Loses accuracy for deeply nested data; may miss large subdirectories

### 3. Disk-Based Counting (Alternative Approach)
```powershell
[io.directory]::GetFiles($folder.FullName, "*", [io.searchoption]::AllDirectories) | Measure-Object
```
**Benefit**: Marginal improvement; different API may cache better
**Trade-off**: Similar performance; less obvious error handling

### 4. SMB-Level Optimization
For network shares: Map drive, work locally, unmap afterward.
**Benefit**: Reduces SMB round-trips
**Trade-off**: Requires admin credentials; more complex code; may not be feasible in all environments

### 5. Caching Results
Store previous scan results; update incrementally.
**Benefit**: Huge win for repeated queries
**Trade-off**: Adds complexity; requires versioning & invalidation logic; outside current scope

## Known Limitations

1. **Hidden/System Files**: Script may not count all files if they're excluded by access control
2. **Sparse Files**: Reported size ≠ actual disk usage (NTFS sparse files)
3. **Hard Links/Junctions**: May double-count if not deduplicated
4. **Network Timeouts**: No timeout handling; very large/slow shares may hang
5. **Top 100 Only**: Results truncated; no pagination

## Recommendations

**For typical use (< 500 GB):**
- Current implementation is acceptable
- Optimize only if performance becomes a problem

**For large enterprise scans (500 GB - 1 TB+):**
- Consider PowerShell 7 with `-Parallel` option
- Implement timeout handling for network shares
- Add progress bar for long operations

**For repeated scanning:**
- Store results in CSV/JSON
- Add `--force` flag to skip cache
- Compare against baseline for delta reporting

## Testing Performance

```powershell
# Measure script execution time
Measure-Command {
    & .\ps-get-dir-size.ps1
}

# Profile specific command
@(Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue) | Measure-Object | Select-Object Count, @{Name="TotalTime";Expression={$_.PSObject.Properties['ExecutionTime']}}
```
