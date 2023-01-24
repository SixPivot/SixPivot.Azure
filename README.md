# SixPivot.Azure PowerShell module

A PowerShell module with Azure-related cmdlets

## Cmdlets

### Find-FreeSubnets

Find unallocated subnet ranges in an Azure Virtual Network.

```powershell
$result = Find-FreeSubnets -ResourceGroup rg-freesubnet-australiaeast -VNetName vnet-freesubnet-australiaeast
```

Displaying `$result`:

```text
VNet Start VNet End     Available Subnets
---------- --------     --------- -------
10.0.0.0   10.0.255.255 {48, 8}   {10.0.0.0/24, 10.0.1.0/28, 10.0.1.64/28, 10.0.1.88/29}
```

`$result.Subnets` contains a list of the existing subnets for this virtual network.

The `$result.Available` property contains information about available IP ranges:

```text
Start     End       Size Available ranges
-----     ---       ---- ----------------
10.0.1.16 10.0.1.63 48   {10.0.1.16/28, 10.0.1.32/27, 10.0.1.32/28, 10.0.1.48/28}
10.0.1.80 10.0.1.87 8
```

The 'Available ranges' array is a list of one or more CIDR ranges that could utilise the available IP addresses.

`$result.Available.CIDRAvailable`

```text
10.0.1.16/28
10.0.1.32/27
10.0.1.32/28
10.0.1.48/28
10.0.1.96/27
10.0.1.96/28
10.0.1.112/28
10.0.1.128/25
10.0.1.128/26
10.0.1.128/27
10.0.1.128/28
10.0.1.144/28
10.0.1.160/27
10.0.1.160/28
10.0.1.176/28
10.0.1.192/26
10.0.1.192/27
10.0.1.192/28
10.0.1.208/28
10.0.1.224/27
10.0.1.224/28
10.0.1.240/28
```
