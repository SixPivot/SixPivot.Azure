# Development notes

The PowerShell code should be compatible with Windows PowerShell as well as PowerShell Core. Tests are run on different combinations of Windows/Linux/PowerShell versions and Az.Network versions.

## Prerequisites

```powershell
Install-Module Pester -RequiredVersion 6.1.0 -Scope CurrentUser -Force
Install-Module Az.Network -Scope CurrentUser -Force
```

## Running Tests

```powershell
Import-Module Pester
$cfg = [PesterConfiguration]::Default
$cfg.Output.Verbosity = 'Detailed'
$cfg.CodeCoverage.Enabled = $true
$cfg.Run.Exit = $true
Invoke-Pester -Configuration $cfg
```

## Deployment

The **ci** workflow contains a final job which creates a new release. The step that does this should use a custom token, rather than the GitHub token, otherwise the **publish** workflow will not be triggered.

The token requires:

- Read access to metadata
- Read and Write access to actions and code.
