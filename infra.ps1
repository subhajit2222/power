#TASK : create rg,vnet,subnet,nsg,vm with public ip in the nsg & storage account 

#VARIABLE DECLERATION

$resourcegroupname = "AEM-RG"
$location = "EastUS"
$vnetname = "AEM-Vnet"
$vnetip = '172.16.0.0/16'
$subnetname = 'AEM-subnet'
$subnetip = '172.16.10.0/24'
$vmname = 'AEM-VM'
$nsgname = 'AEM-NSG'
$publicipname = 'AemVMpublicIP'
$imagename = 'Win2019Datacenter'
$vmsize = 'Standard_B2s'
$storageaccountname = 'aemstorageeastus'
$storageSKU = 'Standard_RAGRS'
$storagekind = 'StorageV2'

#RESOURCE GROUP CREATION
$resourcegroup = New-AzResourceGroup -name $resourcegroupname -Location $location

#CREATE VNET
$vnet = @{
    Name              = $vnetname
    ResourceGroupName = $resourcegroupname
    Location          = $location
    AddressPrefix     = $vnetip
}
$virtualNetwork = New-AzVirtualNetwork @vnet

#SUBNET CREATION INSIDE VNET DEFINED

$subnet = @{
    Name           = $subnetname
    VirtualNetwork = $virtualNetwork
    AddressPrefix  = $subnetip
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet
$virtualNetwork | Set-AzVirtualNetwork

#CREATING NSG RULE
$nsgrule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

#CREATING NSG WITH ADDING NSG RULE
$nsg = New-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $resourcegroupname -Location $location `
    -SecurityRules $nsgrule1

#CREATING VM IP 
$ip = @{
    Name              = $publicipname
    ResourceGroupName = $resourcegroupname
    Location          = $location
    Sku               = 'Standard'
    AllocationMethod  = 'Static'
    IpAddressVersion  = 'IPv4'
    Zone              = 1, 2, 3
}
$mypublicip = New-AzPublicIpAddress @ip

#CREATE VM 
$vmParams = @{
    ResourceGroupName   = $resourcegroupname
    Name                = $vmname
    Location            = $location
    ImageName           = $imagename
    PublicIpAddressName = $publicipname
    OpenPorts           = 3389
    Size                = $vmsize
    virtualnetworkname  = $vnetname
    subnetname          = $subnetname
}
$virtualmachine = New-AzVM @vmParams -SecurityGroupName $nsgrule1 

#STORAGE ACCOUNT CREATION
$Storage = @{
    Name     = $storageaccountname
    Location = $location
    Sku      = $storageSKU
    kind     = $storagekind
}
$storagac = New-AzStorageAccount @Storage -ResourceGroupName $resourcegroupname