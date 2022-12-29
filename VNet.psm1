<#
.SYNOPSIS
    List subnets for a VNet and show any unallocated gaps

.EXAMPLE
    Find-FreeSubnets.ps1 -ResourceGroup rg-myapp-prod-westus-001 -VNetName vnet-myapp-prod-westus-001
#>
function Find-FreeSubnets {
    [CmdletBinding()]
    param (
        [string]
        $ResourceGroup,
        [string]
        $VNetName
    )

    begin {

        # https://gist.github.com/davidjenni/7eb707e60316cdd97549b37ca95fbe93
        function cidrToIpRange {
            param (
                [string] $cidrNotation
            )

            $addr, $maskLength = $cidrNotation -split '/'
            [int]$maskLen = 0
            if (-not [int32]::TryParse($maskLength, [ref] $maskLen)) {
                throw "Cannot parse CIDR mask length string: '$maskLen'"
            }
            if (0 -gt $maskLen -or $maskLen -gt 32) {
                throw "CIDR mask length must be between 0 and 32"
            }
            $ipAddr = [Net.IPAddress]::Parse($addr)
            if ($ipAddr -eq $null) {
                throw "Cannot parse IP address: $addr"
            }
            if ($ipAddr.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
                throw "Can only process CIDR for IPv4"
            }

            $shiftCnt = 32 - $maskLen
            $mask = -bnot ((1 -shl $shiftCnt) - 1)
            $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ipAddr.GetAddressBytes(), 0))
            $ipStart = ($ipNum -band $mask)
            $ipEnd = ($ipNum -bor (-bnot $mask))

            # return as tuple of strings:
            #([BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart)) | ForEach-Object { $_ } ) -join '.'
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart))
            New-Object -TypeName "Net.IPAddress" -argumentList (, $bytes)
            #([BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd)) | ForEach-Object { $_ } ) -join '.'
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd))
            New-Object Net.IPAddress -ArgumentList (, $bytes)
        }

        $vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup

        $vnetStart, $vnetEnd = cidrToIpRange $vnet.AddressSpace.AddressPrefixes

        "VNET $vnetStart - $vnetEnd"

        $sorted = $vnet.Subnets.AddressPrefix | Sort-Object -Property {
            $addr, $maskLength = $_ -split '/'

            $ip = ([Net.IPAddress] $addr)
            $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($ip.GetAddressBytes(), 0))
            $ipNum
        }

        $maskToAddresses = @{ 28 = 16; 27 = 32; 26 = 64; 25 = 128 }
        $addressToStarts = @{
        }

        $maskToAddresses.Values | ForEach-Object {
            $addressToStarts.Add($_, $(for ($i = 0; $i -lt 255; $i += $_) { $i }))
        }

        $nextAvailableNum = 0

        $notFirst = $false

        foreach ($cidr in $sorted) {

            $start, $end = cidrToIpRange $cidr

            $startNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($start.GetAddressBytes(), 0))
            if ($notFirst -and $nextAvailableNum -ne $startNum ) {

                $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($nextAvailableNum))
                $nextAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)

                "Free block(s) of $($startNum - $nextAvailableNum) starting at $nextAvailable"

                for ($i = $nextAvailableNum; $i -lt $startNum; $i += 8) {
                    $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($i))
                    $freeIp = New-Object Net.IPAddress -ArgumentList (, $bytes)

                    foreach ($mask in $maskToAddresses.Keys) {
                        $address = $maskToAddresses[$mask]
                        if ($addressToStarts[$address] -contains $bytes[3] ) {
                            $freeCidr = $freeIp.IPAddressToString + "/$mask"

                            # Check this doesn't overlap next
                            $possibleFreeStart, $possibleFreeEnd = cidrToIpRange $freeCidr

                            $possibleFreeEndNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($possibleFreeEnd.GetAddressBytes(), 0))
                            if ($possibleFreeEndNum -lt $startNum) {
                                "           " + $freeCidr
                            }
                        }
                    }
                }
            }

            $notFirst = $true

            "{0,18} : {1,15} - {2,15}" -f $cidr, $start, $end

            $nextAvailableNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($end.GetAddressBytes(), 0)) + 1

            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd))
        }

        if ($end -ne $vnetEnd) {
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($nextAvailableNum))
            $nextAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)

            "Free block(s) starting at $nextAvailable"
        }
    }
}