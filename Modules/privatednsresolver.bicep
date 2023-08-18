targetScope = 'resourceGroup'
param resname string
param inname string
param outname string
param location string = resourceGroup().location
param inboundsubnetname string
param outboundsubnetname string
param vnetname string
param vnetrg string
param rulename string
@description('Must have fqdn type. Example contoso.local.')
param dnsrules array
param deployrules bool


var dnsforwardingrulesJson = loadJsonContent('../dnsforwardingrules.json')

// if dnsrules are brought in as a parameter use that, else make it possible to load a json
var dnsforwardingrules = !empty(dnsrules) ? dnsrules : dnsforwardingrulesJson
 
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

}

resource inboundEndpoints 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
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
  parent: dnsResolver
}

resource outboundEndpoints 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  name: outname
  location: location
  properties: {
    subnet: {
      id: outboundsubnet.id
    }
  }
  parent: dnsResolver
}

resource lock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: '${resname}-lock'
  properties: {
    level: 'CanNotDelete'
  }
  scope: dnsResolver
}

resource ruleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = if (deployrules) {
  name: rulename
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: resourceId('Microsoft.Network/dnsResolvers/outboundEndpoints',dnsResolver.name,outname)
      }
    ]
  }
 dependsOn: [
      outboundEndpoints
   ]
}

resource dnsdomain 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = [for rule in dnsforwardingrules: if (deployrules) {
  name: rule.name
  properties:{
    domainName: rule.properties.domainName
    targetDnsServers: rule.properties.targetDnsServers
    forwardingRuleState: rule.properties.forwardingRuleState
  }
  parent: ruleset
}]

resource dnsvnetlink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = if (deployrules) {
  name: '${rulename}-Link'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
  }
  parent: ruleset
  dependsOn: [
     dnsdomain
  ]
}


@description('The resource group the Private DNS Resolver was deployed into.')
output resourceGroupName string = resourceGroup().name
// output resolver object = dnsResolver
output outboundsubnet string = outboundsubnet.id
output inboundsubnet string = inboundsubnet.id
output vnet string = vnet.id
output ruleset string = ruleset.name
output dns array = [for (name, i) in dnsforwardingrules: {
  name: name.name
  dnsname: dnsdomain[i].properties.domainName
  nameservers: dnsdomain[i].properties.targetDnsServers
}]
output vnetlink string = dnsvnetlink.id
