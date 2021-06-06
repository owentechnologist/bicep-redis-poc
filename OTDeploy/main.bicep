
var appName = 'drtest'
var fnLoc = 'CentralUS'
var drLoc = 'EastUS'
var redisStorageContainerName = 'redisstorage'
var storageNameExistingStorage = 'otazurestorage1'
var storageNameCentralUS = '${appName}centralus01'
var storageNameEastUS = '${appName}eastus01'
var hostingPlanName = '${appName}-plan'
var appInsightsName = '${appName}-ai'
var fnAppName = '${appName}-fn'
var redisCentralUS = '${appName}-redispoc-centralus'
var redisEastUS = '${appName}-redispoc-eastus'
var SRC_DATABASE_NAME = 'default'
var DEST_DATABASE_NAME = 'default'

resource storageCentralUS 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageNameCentralUS
  location: fnLoc 
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageCentralUS_redisContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageCentralUS.name}/default/${redisStorageContainerName}'
  dependsOn: [
    storageCentralUS
  ]
}

resource storageEastUS 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageNameEastUS
  location: drLoc 
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageEastUS_redisContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageEastUS.name}/default/${redisStorageContainerName}'
  dependsOn: [
    storageEastUS
  ]
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: fnLoc
  kind: 'web'
  properties: { 
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    // circular dependency means we can't reference functionApp directly  /subscriptions/<subscriptionId>/resourceGroups/<rg-name>/providers/Microsoft.Web/sites/<appName>"
     'hidden-link:/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/sites/${fnAppName}': 'Resource'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: hostingPlanName
  location: fnLoc
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
}

resource storageExisting 'Microsoft.Storage/storageAccounts@2021-04-01' existing = {
  name: storageNameExistingStorage
}

resource fnApp 'Microsoft.Web/sites@2021-01-01' = {
  name: fnAppName
  location: fnLoc
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: true
    siteConfig: {
      appSettings: [
        {
          name: 'primaryStorageContainerName'
          value: storageCentralUS_redisContainer.name
        }
        {
          name: 'backupStorageContainerName'
          value: storageEastUS_redisContainer.name
        }
        {
          'name': 'APPINSIGHTS_INSTRUMENTATIONKEY'
          'value': appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageExisting.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageExisting.id, storageExisting.apiVersion).keys[0].value}'
        }
        {
          name: 'drtestredispoccus01_STORAGE'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageCentralUS.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageCentralUS.id, storageCentralUS.apiVersion).keys[0].value}'
        }
        {
          name: 'drtestredispoceus01_STORAGE'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageEastUS.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageEastUS.id, storageEastUS.apiVersion).keys[0].value}'
        }
        {
          name: 'SRC_CLUSTER_NAME'
          value: redisCentralUS
        }
        {
          name: 'DEST_CLUSTER_NAME'
          value: redisEastUS
        }
        {
          name: 'SRC_REDIS_DB_NAME'
          value: SRC_DATABASE_NAME
        }
        {
          name: 'DEST_REDIS_DB_NAME'
          value: DEST_DATABASE_NAME
        }
        {
          name: 'SRC_EXPORT_PATH'
          value: '${redis1.id}/databases/${SRC_DATABASE_NAME}/export?api-version=2021-03-01'
        }
        {
          name: 'DEST_IMPORT_PATH'
          value: '${redis2.id}/databases/${DEST_DATABASE_NAME}/import?api-version=2021-03-01'
        }
        {
          'name': 'FUNCTIONS_EXTENSION_VERSION'
          'value': '~3'
        }
        {
          'name': 'FUNCTIONS_WORKER_RUNTIME'
          'value': 'node'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageExisting.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageExisting.id, storageExisting.apiVersion).keys[0].value}'
        }
        // WEBSITE_CONTENTSHARE will also be auto-generated - https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings#website_contentshare
        // WEBSITE_RUN_FROM_PACKAGE will be set to 1 by func azure functionapp publish
      ]
    }
  }

  dependsOn: [
    appInsights
    hostingPlan
    storageExisting
  ]
}

resource redis1 'Microsoft.Cache/redisEnterprise@2021-02-01-preview' = {
  name: redisCentralUS
  location: fnLoc
  sku: {
      name: 'Enterprise_E10'
      capacity: 2
    }
  }
  
  resource searchDB1_default 'Microsoft.Cache/redisEnterprise/databases@2021-02-01-preview' = {
    parent: redis1
    name: 'default'
    properties: {
      clientProtocol: 'Encrypted'
      evictionPolicy: 'NoEviction'
      clusteringPolicy: 'EnterpriseCluster'
      modules: [
        {
          name: 'RediSearch'
        }
      ]
      persistence: {
        aofEnabled: true
        rdbEnabled: false
        aofFrequency: '1s'
      }
    }
  }

resource redis2 'Microsoft.Cache/redisEnterprise@2021-02-01-preview' = {
  name: redisEastUS
  location: drLoc
  sku: {
    name: 'Enterprise_E10'
    capacity: 2
  } 
}
resource searchDB_BAK_default 'Microsoft.Cache/redisEnterprise/databases@2021-02-01-preview' = {
  parent: redis2
  name: 'default'
  properties: {
    clientProtocol: 'Encrypted'
    evictionPolicy: 'NoEviction'
    clusteringPolicy: 'EnterpriseCluster'
    modules: [
      {
        name: 'RediSearch'
      }
    ]
    persistence: {
      aofEnabled: true
      rdbEnabled: false
      aofFrequency: '1s'
    }
  }
}
