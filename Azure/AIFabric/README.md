# AI Fabric deployment

## Prerequisites

### Orchestrator

An instance of UiPath Orchestrator is needed and it needs to be configured as described [here](https://docs.uipath.com/ai-fabric/docs/3-configure-orchestrator).
There are several options to deploy an instance on Azure:
1. One click deployment using the Azure marketplace [here](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/uipath-5054924.uipath_orchestrator_automated_deployment_webapp?tab=Overview)
2. Command line deployment using the instructions found [here](https://github.com/UiPath/Infrastructure/tree/main/Azure/Orchestrator)

### Azure Resource Group

The deployment is created inside an existing **Azure Resource Group**. The user deploying AI Fabric needs to have the proper permissions. This means either:
- The `Owner` role over the RG, or
- Alternatively, a `Constributor` role can be used, if it is augmented  with `Microsoft.Authorization/roleAssignments/write` over resources created inside the resource group.

Also, the deployment script will be executed under a [User assigned identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli)
This identity needs to have:
- Contributor role over the Subscription
- Owner role over the Resource Group

### Installation token

Generate an installation access token (JWT) on the Orchestrator, as described [here](https://docs.uipath.com/orchestrator/docs/installation-access-token)

## Deployment

The deployment is comprised of several steps:
1. Resources are provisioned inside the resource group via the [mainTemplate.json](mainTemplate.json)
2. The deployment script configures the AKS
3. Finally, Replicated installs the AI Fabric application

Please allow anywhere up to 1 hour for the whole process to complete

### Console deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmain%2FAzure%2FAIFabric%2FmainTemplate.json)


### Command line deployment

The main template can be deployed via command line as well. The repo contains a sample input parameters file [here](mainTemplate.parameters.json).

```shell
az deployment group create --resource-group resource-group --template-file mainTemplate.json --parameters @maintemplate.parameters.json --subscription subscription-name
```

### Input parameters

| Parameter name | Type | Description |
| --- | --- | --- |
| resourceName | string | Name of the AI Fabric deployment AKS cluster |
| licenseField | string | AI Fabric license |
| kubernetesVersion | string | AKS kubernetes version |
| cpusize | string | Azure VM size for cluster nodes without GPU |
| gputype | string | Azure VM size for cluster nodes with GPU |
| orchestratorEndpoint | string | Hostname of Orchestrator |
| identityEndpoint | string | Hostname of Identity Server |
| jwtToken | string | Orchestrator installation access token |
| sqlAdministratorLogin | string | SQL admin login |
| sqlAdministratorLoginPassword | string | SQL admin password |
| exposeKotsAdmin | string | yes/no |
| kotsAdminPassword | string | Password for KOTS access |
| acrSKU | string | ACR SKU |
| identity | object | User assigned identity. Please see [sample](mainTemplate.parameters.json) for format. More information in the ARM docs [here](https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts#userassignedidentities-object) |
| tagsByResource | object | sample: "Microsoft.ContainerService/managedClusters": { "Project": "projectName", "Owner": "john.doe@example.com"} |

## Troubleshooting

### Certificate creation failure

The deployment uses Let's Encrypt to create the SSL certificate. If multiple deployments are attempted using the same `resourceName` parameter, the certificate provider may throttle for the resulting URL. In this case the deployment script log will output:

```
Certification creation failed !! Exiting
```

To overcome this, change the parameter, which in turn will attempt deploying at a different host name.
