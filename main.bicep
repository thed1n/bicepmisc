targetScope = 'subscription'
param privrgname string
param location string = 'swedencentral'
param tags object = {}
param resname string
param inname string
param outname string
param inboundsubnetname string
param outboundsubnetname string
param vnetname string
param vnetrg string
param rulename string
param dnsrules array = []
param deployrules bool

resource privrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: privrgname
  location: location
  tags: !empty(tags) ? tags : null
}


module privatResolver 'Modules/privatednsresolver.bicep' = {
  name: 'PrivateDnsResolver${uniqueString(privrg.id)}'
  #disable-next-line explicit-values-for-loc-params //disabled the rule for locations
  params:{
    dnsrules: !empty(dnsrules) ? dnsrules : []
    inboundsubnetname: inboundsubnetname
    inname: inname
    outboundsubnetname: outboundsubnetname
    outname: outname
    resname: resname
    rulename: rulename
    vnetname: vnetname
    vnetrg: vnetrg
    deployrules: deployrules
    // location defined in module to use the resourceGroup().location
  }
  scope: resourceGroup(privrg.name)
}

output result object = privatResolver.outputs
