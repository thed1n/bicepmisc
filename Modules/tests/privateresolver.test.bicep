targetScope = 'subscription'
param location string = 'swedencentral'



module resolver '../privatednsresolver.bicep' = {
  name: 'test-private-resolver'
  params:{
    dnsrules:[
      {
        name: 'freeze'
        properties: {
          forwardingRuleState: 'Enabled'
          targetDnsServer: [
            {
              ipaddress: '192.168.1.1'
            }
            {
              ipaddress: '192.168.2.1'
            }
          ]
          domainName: 'freeze.local.'
        }
      }
    ]
    rulename: 'superrule'
    inboundsubnetname: 'inbound'
    inname: 'ibe01'
    outboundsubnetname: 'outbound'
    outname: 'obe01'
    resname: 'dnsprsc002'
    vnetname: 'vnet-hub-sc-001'
    vnetrg: 'hub-vnet'
    location: location
    deployrules: true
  }
  scope: resourceGroup('rg-privateresolver')
}
