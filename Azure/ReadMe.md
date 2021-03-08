# How to use these templates to deploy to Azure

## Note
These are the templates we use for the Azure marketplace deployment and we want to offer them to you so you can have a starting point to customize UiPath deployments. These will be automatically uploaded here with any new release.

- We encourage you to fork the repository and create your own variation if needed.
- We welcome any feedback in the form of issues but keep in mind that any fix / feature will have to go through our pipline.
- Since we are offering the marketplace templates in a rather "raw" format, some changes are required so we compiled a list of steps for you to follow for a successful deployment (see below).
- We are still working on the pipeline so the deployment steps are subject to change
- The previous deployments were moved to the `Archived` folder

## Prerequsites
1. Go to the `createUiDefinition.json` file for either Robot or Orchestrator
2. Copy the contents and paste it [here](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade)
3. Click Preview and fill in all the necessary fields according to the deployment type you need
4. In the last tab, `Review + Create` click on `View ouputs payload`
5. Copy the contents from the window that opened to a new parameters file.


## Steps
1. Fork github repository:  
https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/fork-a-repo#fork-an-example-repository
2. Create a folder and navigate to it using a command line tool
3. Clone the forked github repository to a folder of your choosing:
``` cmd
git clone https://github.com/<github username>/Infrastructure.git
```
4. Change directory to `Setup` and run script `Set-DeploymentConfiguration.ps1` with either `-UiPathSolution Robot` or `-UiPathSolution Orchestrator`, depending on what you need:
```powershell
cd Setup
./Set-DeploymentConfiguration.ps1 -UiPathSolution Orchestrator #or Robot
```
5. Upload the files from the `Upload` folder to Azure blob storage (or any other storage solution from where it can be downloaded using an URL). Paths are printed in the command line also. You can use the portal, powershell or az cli.
Az cli examples:
```bash
# Upload blob
az storage blob upload --account-name <storage account name> --container-name <container name> --name <file name> --file <file path>
# Get blob
az storage blob url --account-name <storage account name> --container-name <container name> --name <file name> --output tsv

# Example
az storage blob upload --account-name azmktstorage --container-name container --name file.txt --file "D:\UpiPath\Setup\Upload\file.txt"
az storage blob url --account-name azmktstorage --container-name container --name file.txt --output tsv
```
6. Change URLs as follows (mainTemplate.json):
### Robot:

| Variable Name | Value |
| ------ | -------- |
| `robotArtifact` | Copy the URL from the command that uploaded the `UiPathStudio.msi` file |
| `robotPsUri` | Copy the URL forked repository in the `raw` format for the `Install-AzureRobot.ps1` file. See example below. |
| `azureUtils` | Copy the URL forked repository in the `raw` format for the `AzureUtils.psm1` file. See example below. |
| `installRobotScript` | Copy the URL forked repository in the `raw` format for the `Install-UiPathRobots.ps1` file. See example below. |

### Orchestrator:

| Variable Name | Value |
| ------ | -------- |
| `installPackageUri` | Copy the URL from the command that uploaded the `HAA/haa-2.0.0.tar.gz` file |
| `OrchestratorArtifactsPaaS.OrchestratorArtifact` | Copy the URL from the command that uploaded the `UiPath.Orchestrator.Web.zip` file |
| `IdentityArtifactsPaaS.IdentityPackage` | Copy the URL from the command that uploaded the `UiPath.IdentityServer.Web.zip` file |
| `IdentityArtifactsPaaS.IdentityCliMigrator` | Copy the URL from the command that uploaded the `UiPath.IdentityServer.Migrator.Cli.zip` file |
| `WebhooksArtifactsPaaS.WebhookServicePackage` | Copy the URL from the command that uploaded the `UiPath.WebhookService.Web.zip` file |
| `WebhooksArtifactsPaaS.WebhookMigratePackage` | Copy the URL from the command that uploaded the `UiPath.WebhookService.Migrator.Cli.zip` file |
| `installScriptUri` | **Text**: Copy the URL forked repository in the `raw` format for the `HAA/install-haa.sh` file. See example below. |
| `SQLTemplateUri` | **Text**: Copy the URL forked repository in the `raw` format for the `linkedTemplates/SQL.json` file. See example below. |
| `HAATemplateUri` | **Text**: Copy the URL forked repository in the `raw` format for the `linkedTemplates/HAA.json` file. See example below. |
| `PaaSWithIdentityTemplateUri` | **Text**: Copy the URL forked repository in the `raw` format for the `linkedTemplates/PaaSWithIdentity.json` file. See example below. |
| `OrchestrationVMUri` | **Text**: Copy the URL forked repository in the `raw` format for the `linkedTemplates/OrchestrationVM.json` file. See example below. |
| `CleanUpOrchestrationScriptUri` | **Text**: Copy the URL forked repository in the `raw` format for the `linkedTemplates/CleanUpScriptsTemplate.json` file. See example below. |
| `OrchestratorArtifactsPaaS.PublishOrchestratorScript` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/Publish-Orchestrator.ps1` file. See example below. |
| `OrchestratorArtifactsPaaS.WebDeployPackage` | **Binary**: Copy the URL forked repository in the `raw` format for the `Other/WebDeploy_amd64_en-US.msi` file. See example below. |
| `IdentityArtifactsPaaS.PublishIdentityScript` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/Publish-IdentityServer.ps1` file. See example below. |
| `IdentityArtifactsPaaS.MigrateToIdentityScript` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/MigrateTo-IdentityServer.ps1` file. See example below. |
| `WebhooksArtifactsPaaS.PublishWebhooksScript` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/Publish-Webhooks.ps1` file. See example below. |
| `WebhooksArtifactsPaaS.MigrateToWebhooksScript` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/MigrateTo-Webhooks.ps1` file. See example below. |
| `UtilityArtifactsPaaS.PSUtilsZip` | **Binary**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/ps_utils.zip` file. See example below. |
| `UtilityArtifactsPaaS.AzModulesZip` | **Binary**: Copy the URL forked repository in the `raw` format for the `Other/AzModules.zip` file. See example below. |
| `UtilityArtifactsPaaS.CleanUpOrchestrationResources` | **Binary**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/CleanUpOrchestrationResources.ps1` file. See example below. |
| `UtilityArtifactsPaaS.DeployOrchestratorMainScript` | **Binary**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/Deploy-UiPathOrchestratorPaaS.ps1` file. See example below. |
| `UtilityArtifactsPaaS.AzureUtils` | **Text**: Copy the URL forked repository in the `raw` format for the `<orchestratorVersion>/AzureUtils.psm1` file. See example below. |

Example (text files) for raw github files (you can `right-click` -> `copy link` on the `raw` button): 
`https://raw.githubusercontent.com/<github username>/Infrastructure/main/Azure/<filename>.<text>`  
Example (binary files) for raw github files (you can `right-click` -> `copy link` on the `download` button):  
`https://github.com/UiPath/<github username>/raw/main/<PathToFile>/<filename>.<binary>`

7. Remove the following parameters from `mainTemplate.json`:
```json
"_artifactsLocation": {
            "type": "string",
            "metadata": {
                "description": "The base URI where artifacts required by this template are located including a trailing '/'"
            },
            "defaultValue": "[deployment().properties.templateLink.uri]"
        },
        "_artifactsLocationSasToken": {
            "type": "securestring",
            "metadata": {
                "description": "The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured."
            },
            "defaultValue": ""
        },
```

8. Finally, run:
```bash
# If running from powershell add ` before the @ symbol!
az deployment group create --name <deployment name> --resource-group <resource group name> --template-file <path to mainTemplate.json> --parameters @<parameters file>
```
9. You got yourself a new UiPath deployment, ENJOY!
