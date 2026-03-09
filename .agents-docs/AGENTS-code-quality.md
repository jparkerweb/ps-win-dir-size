# Code Quality & Patterns

> Part of [AGENTS.md](../AGENTS.md) — project guidance for AI coding agents.

## Coding Conventions

### Error Handling Strategy
- **Silent continuation with feedback**: `-ErrorAction SilentlyContinue` used strategically
- **Per-folder try-catch**: Individual directory errors don't halt processing
- **Exit codes**: Return 1 on fatal errors; 0 on success

**Pattern:**
```powershell
try {
    $result = Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue
    # Process $result
}
catch {
    $errorCount++
    Write-Host "[message]: [Access Denied]" -ForegroundColor Yellow
    # Continue to next folder
}
```

### Null Checking
Always validate before calculations:
```powershell
if ($null -eq $size) {
    $size = 0
}
```

This prevents null arithmetic errors and ensures consistent behavior.

### Formatted Output
- **Color-coded console output**: Cyan for headers, Green for status, Yellow for warnings, Red for errors
- **Aligned tables**: Use `Format-Table -AutoSize` for readability
- **Progress indicators**: `[$current/$total]` format for user feedback

### Naming Conventions
- **Variables**: camelCase (`$topLevelFolders`, `$processedFolders`)
- **Functions**: PascalCase with `Format-` prefix for utility functions (`Format-Size`)
- **Parameters**: Use descriptive names (`-Path`, `-Recurse`, `-File`)

## Refactoring Guidelines

### When to Refactor
1. **Code duplication**: If same logic appears 3+ times, extract to function
2. **Function size**: If a function exceeds ~50 lines, split into smaller functions
3. **Parameter explosion**: If a function takes 5+ parameters, consider grouping into object
4. **Complexity**: If logic requires nested loops/conditions 4+ levels deep, extract helper

### What NOT to Refactor
1. **Single-use code**: Utility functions called once are acceptable if they improve readability
2. **Standard patterns**: PowerShell idioms should not be "improved"
3. **Working code**: Don't refactor unless there's a clear benefit (performance, readability, maintainability)

## Best Practices Observed

✅ **Validates input before processing**
```powershell
if (-not (Test-Path -Path $path)) {
    Write-Host "Error: Path '$path' does not exist or is not accessible." -ForegroundColor Red
    exit 1
}
```

✅ **Handles edge cases (null, empty results)**
```powershell
if ($topLevelFolders.Count -eq 0) {
    Write-Host "No subdirectories found in the specified path." -ForegroundColor Yellow
    exit 0
}
```

✅ **Provides progress feedback**
```powershell
Write-Host "[$processedFolders/$totalFolders] $($folder.Name): $formattedSize" -ForegroundColor Gray
```

✅ **Includes summary statistics**
```powershell
Write-Host "Total size of all subdirectories: $(Format-Size -Bytes $totalSize)"
Write-Host "Number of subdirectories scanned: $totalFolders"
Write-Host "Errors encountered: $errorCount"
```

## Best Practices NOT Currently Implemented

❌ **Parameter validation**: Could add `param()` attributes for type checking
- Trade-off: Current simple `param()` is fine for single interactive script

❌ **Logging**: Could write results to file
- Trade-off: Out-of-scope; script designed for interactive use

❌ **Progress bar**: Could use `Write-Progress` for long scans
- Trade-off: Current per-folder output provides adequate feedback

❌ **Configuration file**: Could support `.json` config for default paths
- Trade-off: Adds complexity; not needed for current use case

❌ **PowerShell commenting**: Could add more inline comments
- Trade-off: Code is self-documenting; comments present where logic is non-obvious

## Compatibility & Version Support

**Requires**: PowerShell 5.0+

**Version-specific features used:**
- `@()` for array initialization (5.0+)
- `Get-ChildItem -Directory` filter (5.0+)
- `PSCustomObject` (5.0+)
- `Format-Table -AutoSize -Wrap` (5.0+)

**Not used** (would break 5.0 compatibility):
- `-Parallel` (7.0+)
- Foreach parallel syntax (7.0+)
- Modern string formatting (6.0+)

## Testing Recommendations

| Scenario | How to Test | Expected Outcome |
|----------|-------------|------------------|
| Valid local path | Enter `C:\Users` | Display directory sizes & summary |
| Valid network path | Enter `\\server\share` | Display network directory sizes |
| Invalid path | Enter nonexistent path | Error message & exit code 1 |
| Access denied | Scan system protected folder | Show `[Access Denied]` for restricted items |
| Empty directory | Enter folder with no subdirs | Exit with "No subdirectories found" |
| Very large path | Scan 500+ GB directory | Verify scan completes within reasonable time |
| Deeply nested path | Test path with 10+ levels | Confirm all levels are scanned |

## Security Considerations

**Current state:** No significant security vulnerabilities detected.

- **Input validation**: Path is validated via `Test-Path`
- **Command injection**: Not applicable; user input used only as path parameter
- **File access**: Script respects OS-level file permissions
- **Output**: No sensitive data leakage; only displays folder names and sizes

**Recommendations:**
- If script evolves to accept command-line parameters, validate all inputs
- Consider running in constrained PowerShell environment if processing untrusted paths
