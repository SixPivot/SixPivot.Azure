# BeforeAll {
#     # . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
#     Import-Module $PSScriptRoot\Find-FreeSubnets.psm1 -Force
# }

using module ./VNet.psm1
using module Az.Network

Describe "Find-FreeSubnets" {
    It "Returns expected output" {

        
$vnetWithFragmentedSubnets = @"
{
    "AddressSpace": {
      "AddressPrefixes": [
        "10.0.0.0/16"
      ]
    },
    "DhcpOptions": {
      "DnsServers": null
    },
    "FlowTimeoutInMinutes": null,
    "Subnets": [
      {
        "AddressPrefix": [
          "10.0.0.0/24"
        ],
        "IpConfigurations": [],
        "ServiceAssociationLinks": [],
        "ResourceNavigationLinks": [],
        "NetworkSecurityGroup": null,
        "RouteTable": null,
        "NatGateway": null,
        "ServiceEndpoints": [],
        "ServiceEndpointPolicies": [],
        "Delegations": [],
        "PrivateEndpoints": [],
        "ProvisioningState": "Succeeded",
        "PrivateEndpointNetworkPolicies": "Disabled",
        "PrivateLinkServiceNetworkPolicies": "Enabled",
        "IpAllocations": [],
        "Name": "default",
        "Etag": "W/\"99f7188e-bab9-4a66-a685-a3e5acb123fd\"",
        "Id": "/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/default"
      },
      {
        "AddressPrefix": [
          "10.0.1.0/28"
        ],
        "IpConfigurations": [],
        "ServiceAssociationLinks": [],
        "ResourceNavigationLinks": [],
        "NetworkSecurityGroup": null,
        "RouteTable": null,
        "NatGateway": null,
        "ServiceEndpoints": [],
        "ServiceEndpointPolicies": [],
        "Delegations": [],
        "PrivateEndpoints": [],
        "ProvisioningState": "Succeeded",
        "PrivateEndpointNetworkPolicies": "Disabled",
        "PrivateLinkServiceNetworkPolicies": "Enabled",
        "IpAllocations": [],
        "Name": "subnet-freesubnet-australiaeast",
        "Etag": "W/\"99f7188e-bab9-4a66-a685-a3e5acb123fd\"",
        "Id": "/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast"
      },
      {
        "AddressPrefix": [
          "10.0.1.88/29"
        ],
        "IpConfigurations": [],
        "ServiceAssociationLinks": [],
        "ResourceNavigationLinks": [],
        "NetworkSecurityGroup": null,
        "RouteTable": null,
        "NatGateway": null,
        "ServiceEndpoints": [],
        "ServiceEndpointPolicies": [],
        "Delegations": [],
        "PrivateEndpoints": [],
        "ProvisioningState": "Succeeded",
        "PrivateEndpointNetworkPolicies": "Disabled",
        "PrivateLinkServiceNetworkPolicies": "Enabled",
        "IpAllocations": [],
        "Name": "subnet-freesubnet-australiaeast-002",
        "Etag": "W/\"99f7188e-bab9-4a66-a685-a3e5acb123fd\"",
        "Id": "/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast-002"
      },
      {
        "AddressPrefix": [
          "10.0.1.64/28"
        ],
        "IpConfigurations": [],
        "ServiceAssociationLinks": [],
        "ResourceNavigationLinks": [],
        "NetworkSecurityGroup": null,
        "RouteTable": null,
        "NatGateway": null,
        "ServiceEndpoints": [],
        "ServiceEndpointPolicies": [],
        "Delegations": [],
        "PrivateEndpoints": [],
        "ProvisioningState": "Succeeded",
        "PrivateEndpointNetworkPolicies": "Disabled",
        "PrivateLinkServiceNetworkPolicies": "Enabled",
        "IpAllocations": [],
        "Name": "subnet-freesubnet-australiaeast-001",
        "Etag": "W/\"99f7188e-bab9-4a66-a685-a3e5acb123fd\"",
        "Id": "/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast-001"
      }
    ],
    "BgpCommunities": null,
    "Encryption": null,
    "VirtualNetworkPeerings": [],
    "ProvisioningState": "Succeeded",
    "EnableDdosProtection": false,
    "DdosProtectionPlan": null,
    "IpAllocations": [],
    "ExtendedLocation": null,
    "ResourceGroupName": "rg-freesubnet-australiaeast",
    "Location": "australiaeast",
    "ResourceGuid": "c0c009f8-d32b-433c-a30a-b5f4b70a1506",
    "Type": "Microsoft.Network/virtualNetworks",
    "Tag": {},
    "TagsTable": null,
    "Name": "vnet-freesubnet-australiaeast",
    "Etag": "W/\"99f7188e-bab9-4a66-a685-a3e5acb123fd\"",
    "Id": "/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast",
    "AddressSpaceText": "{\r\n  \"AddressPrefixes\": [\r\n    \"10.0.0.0/16\"\r\n  ]\r\n}",
    "DhcpOptionsText": "{}",
    "FlowTimeoutInMinutesText": "null",
    "SubnetsText": "[\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"default\",\r\n    \"Etag\": \"W/\\\"99f7188e-bab9-4a66-a685-a3e5acb123fd\\\"\",\r\n    \"Id\": \"/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/default\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.0.0/24\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ServiceAssociationLinks\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"PrivateEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\",\r\n    \"PrivateEndpointNetworkPolicies\": \"Disabled\",\r\n    \"PrivateLinkServiceNetworkPolicies\": \"Enabled\",\r\n    \"IpAllocations\": []\r\n  },\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"subnet-freesubnet-australiaeast\",\r\n    \"Etag\": \"W/\\\"99f7188e-bab9-4a66-a685-a3e5acb123fd\\\"\",\r\n    \"Id\": \"/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.1.0/28\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ServiceAssociationLinks\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"PrivateEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\",\r\n    \"PrivateEndpointNetworkPolicies\": \"Disabled\",\r\n    \"PrivateLinkServiceNetworkPolicies\": \"Enabled\",\r\n    \"IpAllocations\": []\r\n  },\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"subnet-freesubnet-australiaeast-002\",\r\n    \"Etag\": \"W/\\\"99f7188e-bab9-4a66-a685-a3e5acb123fd\\\"\",\r\n    \"Id\": \"/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast-002\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.1.88/29\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ServiceAssociationLinks\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"PrivateEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\",\r\n    \"PrivateEndpointNetworkPolicies\": \"Disabled\",\r\n    \"PrivateLinkServiceNetworkPolicies\": \"Enabled\",\r\n    \"IpAllocations\": []\r\n  },\r\n  {\r\n    \"Delegations\": [],\r\n    \"Name\": \"subnet-freesubnet-australiaeast-001\",\r\n    \"Etag\": \"W/\\\"99f7188e-bab9-4a66-a685-a3e5acb123fd\\\"\",\r\n    \"Id\": \"/subscriptions/b4b2e7e9-66e7-46b5-a56b-cce2b50011d4/resourceGroups/rg-freesubnet-australiaeast/providers/Microsoft.Network/virtualNetworks/vnet-freesubnet-australiaeast/subnets/subnet-freesubnet-australiaeast-001\",\r\n    \"AddressPrefix\": [\r\n      \"10.0.1.64/28\"\r\n    ],\r\n    \"IpConfigurations\": [],\r\n    \"ServiceAssociationLinks\": [],\r\n    \"ResourceNavigationLinks\": [],\r\n    \"ServiceEndpoints\": [],\r\n    \"ServiceEndpointPolicies\": [],\r\n    \"PrivateEndpoints\": [],\r\n    \"ProvisioningState\": \"Succeeded\",\r\n    \"PrivateEndpointNetworkPolicies\": \"Disabled\",\r\n    \"PrivateLinkServiceNetworkPolicies\": \"Enabled\",\r\n    \"IpAllocations\": []\r\n  }\r\n]",
    "BgpCommunitiesText": "null",
    "EncryptionText": "null",
    "VirtualNetworkPeeringsText": "[]",
    "EnableDdosProtectionText": "false",
    "DdosProtectionPlanText": "null",
    "IpAllocationsText": "[]",
    "ExtendedLocationText": "null"
  }  
"@ | ConvertFrom-Json

$expected = (@'
VNET 10.0.0.0 - 10.0.255.255
       10.0.0.0/24 :        10.0.0.0 -      10.0.0.255
       10.0.1.0/28 :        10.0.1.0 -       10.0.1.15
Free block(s) of 48 starting at 10.0.1.16
           10.0.1.16/28
           10.0.1.32/27
           10.0.1.32/28
           10.0.1.48/28
      10.0.1.64/28 :       10.0.1.64 -       10.0.1.79
Free block(s) of 8 starting at 10.0.1.80
      10.0.1.88/29 :       10.0.1.88 -       10.0.1.95
Free block(s) starting at 10.0.1.96
'@)

        $expected = $expected.Split("`r`n")

        Mock -ModuleName VNet -CommandName Get-AzVirtualNetwork { return $vnetWithFragmentedSubnets }

        Find-FreeSubnets -ResourceGroup rg-freesubnet-australiaeast -VNetName vnet-freesubnet-australiaeast | Should -Be $expected
    }
}
