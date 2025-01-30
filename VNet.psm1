class Subnet {
    [string] $CIDR
    [NET.IPAddress] $Start
    [NET.IPAddress] $End

    [string] ToString() {
        return $this.CIDR
    }
}

class VNetRange {
    [NET.IPAddress] $Start
    [NET.IPAddress] $End

    [string] ToString() {
        return $this.Start + "-" + $this.End
    }
}

class Free {
    [NET.IPAddress] $Start
    [NET.IPAddress] $End
    [int] $Size
    [string[]] $CIDRAvailable

    [string] ToString() {
        return $this.Size
    }
}

class VNetSummary {
    [string] $VNetStart
    [string] $VNetEnd
    [VNetRange[]] $VNetRanges
    [free[]] $Available
    [subnet[]] $Subnets
}

<#
.SYNOPSIS
    List subnets for a VNet and show any unallocated gaps

.DESCRIPTION
    Returns a list of subnets in use for a particular VNET and also any gaps available

.PARAMETER ResourceGroup
    The name of the resource group that contains a virtual network

.PARAMETER VNetName
    The name of the virtual network to query for subnets

.NOTES
    This function uses Azure PowerShell cmdlets, so assumes that you've already run Connect-AzAccount to sign in to Azure.

.EXAMPLE
    $result = Find-FreeSubnets -ResourceGroup rg-freesubnet-australiaeast -VNetName vnet-freesubnet-australiaeast

    Displaying $result:

    VNet Start VNet End     Available Subnets
    ---------- --------     --------- -------
    10.0.0.0   10.0.255.255 {48, 8}   {10.0.0.0/24, 10.0.1.0/28, 10.0.1.64/28, 10.0.1.88/29}

    If the virtual network has multiple address ranges, VNetStart and VNetEnd are those of the last range.
    In that case, 'Available' and 'Subnets' contain all available ranges and all subnets of all address ranges.

    'VNetRanges' contains the start and end of each address range in the virtual network.

    And the 'Available' property contains:

    Start     End       Size Available ranges
    -----     ---       ---- ----------------
    10.0.1.16 10.0.1.63 48   {10.0.1.16/28, 10.0.1.32/27, 10.0.1.32/28, 10.0.1.48/28}
    10.0.1.80 10.0.1.87 8

    The 'Available ranges' array is a list of one or more CIDR ranges that could utilise the available IP addresses.
#>
function Find-FreeSubnets {
    [CmdletBinding()]
    [OutputType([VNetSummary])]
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
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipStart))
            New-Object -TypeName "Net.IPAddress" -argumentList (, $bytes)
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd))
            New-Object Net.IPAddress -ArgumentList (, $bytes)
        }

        $vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup
        $result = [VNetSummary]::new()

        $vnetAddressPrefixes = $vnet.AddressSpace.AddressPrefixes
        foreach($addressPrefix in $vnetAddressPrefixes)
        {
            [Net.IPAddress] $vnetStart, [Net.IPAddress] $vnetEnd = cidrToIpRange $addressPrefix

            $result.VNetStart = $vnetStart
            $result.VNetEnd = $vnetEnd

            $vnetRange = [VNetRange]::new()
            $vnetRange.Start = $vnetStart
            $vnetRange.End = $vnetEnd
            $result.VNetRanges += $vnetRange

            # Create fake subnet immediately following the end of the VNet
            $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($vnetEnd.GetAddressBytes(), 0)) + 1
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipNum))
            [Net.IPAddress] $afterLastAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)

            $afterLastAvailableCidr = "$afterLastAvailable/31"

            # create fake subnet immediately before the start of the VNet
            $ipNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($vnetStart.GetAddressBytes(), 0)) - 1
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipNum))
            [Net.IPAddress] $beforeFirstAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)

            $beforeFirstAvailableCidr = "$beforeFirstAvailable/31"

            $sorted = @($beforeFirstAvailableCidr) + @($vnet.Subnets.AddressPrefix) + @($afterLastAvailableCidr) | Sort-Object -Property {
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

                    $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($startNum - 1))
                    $lastAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)

                    $free = [Free]::new()
                    $free.Start = $nextAvailable
                    $free.End = $lastAvailable
                    $free.Size = $startNum - $nextAvailableNum
                    $result.Available += $free

                    for ($i = $nextAvailableNum; $i -lt $startNum; $i += 8) {
                        $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($i))
                        $freeIp = New-Object Net.IPAddress -ArgumentList (, $bytes)

                        foreach ($mask in ($maskToAddresses.Keys | Sort-Object)) {
                            $address = $maskToAddresses[$mask]
                            if ($addressToStarts[$address] -contains $bytes[3] ) {
                                $freeCidr = $freeIp.IPAddressToString + "/$mask"

                                # Check this doesn't overlap next
                                $possibleFreeStart, $possibleFreeEnd = cidrToIpRange $freeCidr

                                $possibleFreeEndNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($possibleFreeEnd.GetAddressBytes(), 0))
                                if ($possibleFreeEndNum -lt $startNum) {
                                    $free.CIDRAvailable += $freeCidr
                                }
                            }
                        }
                    }
                }

                $notFirst = $true

                if ($cidr -ne $afterLastAvailableCidr -and $cidr -ne $beforeFirstAvailableCidr) {
                    $subnet = [Subnet]::new()
                    $subnet.CIDR = $cidr
                    $subnet.Start = $start
                    $subnet.End = $end
                    $result.Subnets += $subnet
                }

                $nextAvailableNum = [Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($end.GetAddressBytes(), 0)) + 1

                $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($ipEnd))
            }
        }

        if ($end -ne $vnetEnd) {
            $bytes = [BitConverter]::GetBytes([Net.IPAddress]::HostToNetworkOrder($nextAvailableNum))
            $nextAvailable = New-Object Net.IPAddress -ArgumentList (, $bytes)
        }

        $result
    }
}
