#Requires -Module Pester
#Requires -Module VNet
<#
.SYNOPSIS
    VNetSummary objects are equivalent
#>
function Should-BeVNetSummary {
    #[Diagnostics.CodeAnalysis.SuppressMessage("PSUseApprovedVerbs")]
    param(
        [VNetSummary] $ActualValue,
        [switch] $Negate,
        #[Diagnostics.CodeAnalysis.SuppressMessage("PSReviewUnusedParameter")]
        $CallerSessionState,
        [VNetSummary] $ExpectedValue
    )

    begin {
        if ($Negate.IsPresent) {
            throw "-Negate is not supported"
        }

        $failureMessage = Compare-Object -ReferenceObject $ExpectedValue -DifferenceObject $ActualValue -Property VNetStart, VNetEnd, Available, Subnets

        if ($failureMessage) {
            $succeeded = $false
        }
        else {
            $succeeded = $true
        }

        return [pscustomobject]@{
            Succeeded      = $succeeded
            FailureMessage = $failureMessage
        }
    }
}

Add-ShouldOperator -Name BeVNetSummary `
    -InternalName 'Should-BeVNetSummary' `
    -Test ${function:Should-BeVNetSummary}