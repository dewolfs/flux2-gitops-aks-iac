param location string = 'northeurope'

resource managedClusters 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' = {
  name: 'aks01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks01'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool1'
        count: 2
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 30
        mode: 'System'
      }
    ]
  }
}

resource mcFlux_extensions 'Microsoft.KubernetesConfiguration/extensions@2022-04-02-preview' = {
  name: 'flux'
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
  }
  scope: managedClusters
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01' = {
  scope: managedClusters
  name: 'bootstrap'
  properties: {
    scope: 'cluster'
    namespace: 'cluster-config'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: 'https://github.com/dewolfs/flux2-aks-apps.git'
      repositoryRef: {
        branch: 'main'
      }
      syncIntervalInSeconds: 120
    }
    kustomizations: {
      'infra': {
        path: './infra'
        syncIntervalInSeconds: 120
        prune: true
      }
      'apps-dev': {
        path: './apps/kuard/overlays/dev'
        syncIntervalInSeconds: 120
        prune: true
        dependsOn: [
          'infra'
        ]
      }
      'apps-prd': {
        path: './apps/kuard/overlays/prd'
        syncIntervalInSeconds: 120
        prune: true
        dependsOn: [
          'apps-dev'
        ]
      }
    }
  }
  dependsOn: [
    mcFlux_extensions
  ]
}
