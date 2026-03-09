# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-09

### Added

- Interactive prompt to enter a local or network path for analysis
- Recursive size calculation for all top-level subdirectories
- Real-time progress output showing each directory as it is scanned (`[N/Total] Name: Size`)
- Top 100 largest directories summary sorted by size descending
- Multiple size format display (bytes, MB, GB) in results table
- `Format-Size` helper function for human-readable byte formatting (KB/MB/GB)
- Graceful handling of access-denied errors — affected directories are marked and scanning continues
- Path validation (existence check and directory-type check) before scanning begins
- Summary statistics on scan completion: total size, directory count, error count
- Support for both local paths (e.g., `C:\Users`) and network SMB shares (e.g., `\\server\share`)
- Requires PowerShell 5.0 or higher (`#Requires -Version 5.0`)
