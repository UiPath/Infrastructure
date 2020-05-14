# UiPathOrchestrator WebHooks

This ARM template will deploy UiPath Orchestrator WebHooks to an existing WebApp in Azure.

## Prerequisites: 
        ⋅⋅* Existing WebApp, SQL Server DB and licensed Orchestrator 20.x.

## Parameters
        ⋅⋅* "servicePlanName":  "Existing name of the Azure Service PlanName"
        ⋅⋅* "webHooksPackageURL": "Web hooks package URL"
        ⋅⋅* "SQLServerName": "SQL Azure DB Server name"
        ⋅⋅* "SQLServerDBName": "SQL Azure DB name"
        ⋅⋅* "SQLServerAdminLogin": "SQL Azure DB administrator  user login"
        ⋅⋅* "SQLServerAdminPassword": "Database admin user password"

In addition to running the deployment ARM template, end user also needs to make the following changes in Azure Portal:
    </br> On the Azure Web App that's hosting Orchestrator, update the web.config, adding "Webhooks.LedgerIntegration.Enabled" and setting it to true to turn on the new webhook service.



[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FUiPath%2FInfrastructure%2Fmaster%2FAzure%2FOrchestrator%2FPaaS%2FWebHooks%2Fazuredeploy.json)
