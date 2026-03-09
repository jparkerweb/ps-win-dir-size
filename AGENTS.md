# AGENTS.md

This file provides guidance to AI coding agents like Claude Code (claude.ai/code), Cursor AI, Codex, Gemini CLI, GitHub Copilot, and other AI coding assistants when working with code in this repository.

## Project Overview

**ps-get-dir-size** is a PowerShell script utility for analyzing disk space usage on local and network paths. It enumerates top-level subdirectories, calculates their sizes, and displays the largest directories ranked by storage consumption. The tool is designed for system administrators and power users who need to identify disk space bottlenecks quickly.

**Key characteristics:**
- Single PowerShell script (`ps-get-dir-size.ps1`) with interactive path input
- Network path support (SMB shares) and local paths
- Real-time progress feedback during scanning
- Graceful error handling for access-denied scenarios
- Output in multiple size formats (bytes, MB, GB)

## Development Commands

| Command | Purpose |
|---------|---------|
| `./ps-get-dir-size.ps1` | Run the script interactively and enter a path when prompted |
| `Get-Content ps-get-dir-size.ps1` | View the script source code |
| `Test-Path "path"` | Validate a path exists before testing script behavior |

Details: [Development Commands](./.agents-docs/AGENTS-development-commands.md)

## Architecture

The script uses a functional, linear structure optimized for simplicity and performance:

1. **Format-Size Function** - Converts bytes to human-readable format (KB/MB/GB)
2. **User Input Phase** - Interactive prompt for path validation
3. **Directory Enumeration** - Recursively scans top-level subdirectories
4. **Error Handling** - Catches access-denied errors per folder, continues scanning
5. **Output Formatting** - Displays sorted results with multiple size formats

Details: [Architecture](./.agents-docs/AGENTS-architecture.md)

## Git Commit Messages
**Format rules:**
- Brief description (imperative mood, under 72 characters)
- Do NOT include "Claude Code" attribution in the message itself

## How to Use This File

This file serves as an index for the project. Each section contains a brief summary with a link to detailed documentation in `.agents-docs/`. Only read what's relevant to your current task. Inline sections (Project Overview, Git Commit Messages, this section) contain complete information. For expanded guidance, follow the detail links.

---

## Performance & Considerations

- **Scan Time**: Local drives (100 GB) typically complete in 10-30 seconds; network shares 30-120 seconds
- **Large Directories**: The script uses `-Recurse` on each top-level folder, which can be memory-intensive for very deep structures
- **Network Timeouts**: Possible on extremely large or slow network shares
- **Limitations**: Only analyzes immediate subdirectories; hidden/system files may be excluded

Details: [Performance & Optimization](./.agents-docs/AGENTS-performance-optimization.md)

## Code Quality & Patterns

**Conventions:**
- Error handling: Silent continuation with visual feedback (`-ErrorAction SilentlyContinue`)
- Null checking: Always validate before calculations (`if ($null -eq $size)`)
- Formatting: Use PowerShell built-in cmdlets (`Format-Table`, `Format-Size`)
- Progress: Real-time console feedback with color-coded output

Details: [Code Quality](./.agents-docs/AGENTS-code-quality.md)
