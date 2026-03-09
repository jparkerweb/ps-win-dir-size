# Development Commands

> Part of [AGENTS.md](../AGENTS.md) — project guidance for AI coding agents.

## Running the Script

```powershell
# Interactive mode (prompts for path)
.\ps-get-dir-size.ps1

# Alternative name used in README
.\Get-DirectorySize.ps1
```

**Note:** The script filename in the repository is `ps-get-dir-size.ps1`, not `Get-DirectorySize.ps1`. Both names refer to the same functionality.

## Testing & Validation

```powershell
# Test if a path exists and is accessible
Test-Path -Path "C:\Users"
Test-Path -Path "\\server\share"

# Check PowerShell version (script requires 5.0+)
$PSVersionTable.PSVersion

# Run script with specific path (by modifying the script or piping)
# Current implementation requires interactive input
```

## Execution Policy (if needed)

```powershell
# Set execution policy to allow running scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# For one-time execution without changing policy
powershell -ExecutionPolicy Bypass -File .\ps-get-dir-size.ps1
```

## Common Testing Scenarios

- **Local path**: `C:\Users`, `C:\Program Files`
- **Network share**: `\\server\share`, `\\hostname\sharename`
- **Access-denied scenarios**: Protected system folders (will show `[Access Denied]`)
- **Empty directories**: Folders with no subdirectories (will exit with "No subdirectories found")

## Troubleshooting Commands

```powershell
# View script content
Get-Content ps-get-dir-size.ps1

# Test path accessibility
Test-Path "\\problematic\path"
Get-Item "\\problematic\path" -ErrorAction Stop

# Check for encoding issues
File -bi ps-get-dir-size.ps1  # Show file encoding
```
