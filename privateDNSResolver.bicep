param resname string
param inname string
param outname string
param location string = resourceGroup().location
param inboundsubnetname string
param outboundsubnetname string
param vnetname string
param vnetrg string


resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetname
  scope: resourceGroup(vnetrg)
}

resource inboundsubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: inboundsubnetname
  parent: vnet
}

resource outboundsubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: outboundsubnetname
  parent: vnet
}

resource dnsResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: resname
  location: location
  properties: {
     virtualNetwork: {
      id: vnet.id
     }
  }

  resource inboundEndpoints 'inboundEndpoints' = {
    name: inname
    location: location
    properties: {
      ipConfigurations: [
        {
          subnet: {
            id: inboundsubnet.id
          }
        }
      ]
    }
  }

  resource outboundEndpoints 'outboundEndpoints' = {
    name: outname
    location: location
    properties: {
      subnet: {
        id: outboundsubnet.id
      }
    }
  }
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: '${resname}-lock'
  properties: {
    level: 'CanNotDelete'
  }
  scope: dnsResolver
}

@description('The resource group the Private DNS Resolver was deployed into.')
output resourceGroupName string = resourceGroup().name
output outboundsubnet string = outboundsubnet.id
output inboundsubnet string = inboundsubnet.id
output vnet string = vnet.id
