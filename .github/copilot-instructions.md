# SixPivot.Azure Copilot Instructions

## Project Overview

A PowerShell module that provides Azure VNet utilities. Currently exports one main function: `Find-FreeSubnets`, which identifies unallocated subnet ranges in Azure Virtual Networks.

The module is compatible with both Windows PowerShell (5.1+) and PowerShell Core, and tested across multiple PowerShell versions and Az.Network SDK versions.

## Architecture

### Module Structure

**Core files:**
- `VNet.psm1` - Main module containing classes and the public `Find-FreeSubnets` function
- `SixPivot.Azure.psd1` - Module manifest (declares NestedModules, FormatsToProcess, FunctionsToExport)
- `VNet.Format.ps1xml` - Custom formatting for output objects
- `VNetCustomAssertions.psm1` - Custom Pester assertions for testing

### Key Classes

All classes are defined at the module level in `VNet.psm1`:

- **`Subnet`** - Represents a subnet with properties: `CIDR` (string), `Start` (IPAddress), `End` (IPAddress)
- **`VNetRange`** - Represents a virtual network address range: `Start`, `End` (both IPAddress)
- **`Free`** - Represents available IP ranges: `Start`, `End`, `Size` (int), `CIDRAvailable` (string array)
- **`VNetSummary`** - Main return object containing: `VNetStart`, `VNetEnd`, `VNetRanges`, `Available`, `Subnets`

### Data Flow

1. `Find-FreeSubnets` calls `Get-AzVirtualNetwork` to fetch VNet details
2. Helper function `cidrToIpRange` (in the `begin` block) converts CIDR notation to IP ranges
3. Algorithm identifies gaps between existing subnets and calculates available CIDR ranges
4. Returns `VNetSummary` object with all results

## Build, Test & Lint Commands

### Prerequisites

```powershell
Install-Module Pester -Scope CurrentUser -Force
Install-Module Az.Network -Scope CurrentUser -Force
```

### Run All Tests

```powershell
Import-Module Pester
$cfg = [PesterConfiguration]::Default
$cfg.Output.Verbosity = 'Detailed'
$cfg.CodeCoverage.Enabled = $true
$cfg.Run.Exit = $true
Invoke-Pester -Configuration $cfg
```

This runs `VNet.Tests.ps1` with code coverage reporting enabled.

### Run Single Test

```powershell
Invoke-Pester -Path VNet.Tests.ps1 -TestName "Returns expected output"
```

### Code Analysis

```powershell
Import-Module PSScriptAnalyzer
Get-ChildItem -Path . -Filter *.ps* -Recurse -File | Invoke-ScriptAnalyzer
```

## Key Conventions

### PowerShell Function Conventions

- All public functions use XML comment blocks with full documentation:
  - `.SYNOPSIS` - Brief description
  - `.DESCRIPTION` - Detailed explanation
  - `.PARAMETER` - For each parameter
  - `.NOTES` - Important notes (e.g., prerequisite: Connect-AzAccount)
  - `.EXAMPLE` - Usage example with expected output

### Code Patterns

- **Helper functions in `begin` block** - Functions like `cidrToIpRange` are defined in the `begin` block of `Find-FreeSubnets` rather than at module level to keep them private.

- **Classes with ToString() methods** - All custom classes override `ToString()` for clean console output (e.g., `Subnet` returns CIDR, `Free` returns Size).

- **IP manipulation** - CIDR conversions use bitwise operations with `[Net.IPAddress]` and `[BitConverter]` for IPv4 address math. See helper `cidrToIpRange` for the pattern.

- **Custom Pester assertions** - `VNetCustomAssertions.psm1` defines custom should operators via `Add-ShouldOperator`. This allows writing `$actual | Should -BeVNetSummary $expected` in tests.

### Testing with Pester

- Test file: `VNet.Tests.ps1`
- Uses `using module ./VNet.psm1` and `using module Az.Network` to load dependencies
- Imports custom assertions with `Import-Module` in `BeforeDiscovery` block
- Test data is embedded in test file as JSON strings for reproducibility

## CI/CD Pipeline

### Workflows Location

- `.github/workflows/ci.yml` - Runs tests on multiple platforms
- `.github/workflows/code-analysis.yml` - Runs PSScriptAnalyzer
- `.github/workflows/publish.yml` - Publishes to PowerShell Gallery

### Test Matrix

Tests are run on combinations of:
- **PowerShell versions**: 7.4, 7.5, 7.6 (preview)
- **Linux**: Ubuntu 20.04, 22.04, 24.04
- **Windows**: Windows Server 2022, 2025
- **Az.Network versions**: 5.2.0, 7.0.0, 7.19.0

This ensures the module works across different environments and dependency versions.

### Release Process

- Uses Nerdbank.GitVersioning for versioning
- Triggered on pushes to `main` after all tests pass
- Creates GitHub release with auto-generated release notes
- Uses a custom token (not the default GitHub token) to trigger downstream publish workflow

## Important Dependencies

- **Az.Network module** - Required to run the module and tests. Version 5.2.0 and above are tested.
- **Pester** - Testing framework (v5+)
- **PSScriptAnalyzer** - Static code analysis
- **ConvertToSARIF** - Converts PSScriptAnalyzer output to SARIF format for GitHub Security tab

## Notes for Contributors

- Code should work with Windows PowerShell 5.1 and PowerShell Core (7.4+)
- IP address calculations use IPv4 only; IPv6 support is out of scope
- When adding new functions, follow the same XML comment conventions
- Keep helper functions in the `begin` block if they're function-private
- Add custom Pester assertions to `VNetCustomAssertions.psm1`, not inline in tests
